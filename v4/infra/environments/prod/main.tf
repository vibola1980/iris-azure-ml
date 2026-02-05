# ============================================
# Production Environment - Main Configuration
# Iris ML API v4 - Azure AKS Enterprise Template
# ============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration (uncomment for remote state)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "iris-ml-v4-prod.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Local variables
locals {
  project_name  = "iris"
  environment   = "prod"
  location      = var.location
  unique_suffix = random_string.suffix.result

  tags = {
    Project     = "iris-ml-v4"
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# Current user/service principal for Terraform
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.project_name}-${local.environment}"
  location = local.location
  tags     = local.tags
}

# Networking
module "networking" {
  source = "../../modules/networking"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  vnet_address_space                      = ["10.2.0.0/16"]
  aks_subnet_address_prefix               = ["10.2.0.0/20"]
  private_endpoints_subnet_address_prefix = ["10.2.16.0/24"]

  tags = local.tags
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  log_retention_days    = 90
  alert_email_addresses = var.alert_email_addresses
  enable_alerts         = true
  cpu_alert_threshold   = 70
  memory_alert_threshold = 80

  tags = local.tags
}

# Container Registry
module "acr" {
  source = "../../modules/acr"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  sku                        = "Premium"
  admin_enabled              = false
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id

  tags = local.tags
}

# Storage (for ML models)
module "storage" {
  source = "../../modules/storage"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  name_suffix         = local.unique_suffix

  account_tier              = "Standard"
  replication_type          = "GRS"
  enable_versioning         = true
  blob_soft_delete_days     = 30
  container_soft_delete_days = 30

  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id

  tags = local.tags
}

# Key Vault
module "keyvault" {
  source = "../../modules/keyvault"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  name_suffix         = local.unique_suffix

  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id

  secrets = {
    "api-key"            = var.api_key
    "storage-access-key" = module.storage.primary_access_key
  }

  tags = local.tags
}

# Grant Terraform user access to Key Vault secrets
resource "azurerm_role_assignment" "terraform_keyvault_secrets" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# AKS Cluster
module "aks" {
  source = "../../modules/aks"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  kubernetes_version  = "1.32"
  system_node_vm_size = "Standard_D2s_v3"
  system_node_count   = 3
  enable_autoscaling  = true
  system_node_min_count = 3
  system_node_max_count = 5

  # ML node pool for inference workloads
  enable_ml_node_pool = true
  ml_node_vm_size     = "Standard_D4s_v3"
  ml_node_count       = 2
  ml_node_min_count   = 2
  ml_node_max_count   = 5

  # Azure AD RBAC
  enable_azure_ad_rbac     = var.enable_azure_ad_rbac
  admin_group_object_ids   = var.admin_group_object_ids

  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.id
  enable_acr_integration     = true

  tags = local.tags
}

# Update monitoring with AKS cluster ID for alerts
resource "null_resource" "update_monitoring_alerts" {
  triggers = {
    aks_cluster_id = module.aks.cluster_id
  }

  provisioner "local-exec" {
    command = "echo 'AKS cluster created: ${module.aks.cluster_name}'"
  }
}

# Grant AKS access to Key Vault
resource "azurerm_role_assignment" "aks_keyvault" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.kubelet_identity
}

# Grant AKS access to Storage
resource "azurerm_role_assignment" "aks_storage" {
  scope                = module.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.aks.kubelet_identity
}
