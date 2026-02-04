# ============================================
# Development Environment - Main Configuration
# Iris ML API v4 - Azure AKS Enterprise Template
# ============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }

  # Backend configuration (uncomment for remote state)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "iris-ml-v4-dev.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# Local variables
locals {
  project_name = "iris"
  environment  = "dev"
  location     = var.location

  tags = {
    Project     = "iris-ml-v4"
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

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

  vnet_address_space                      = ["10.1.0.0/16"]
  aks_subnet_address_prefix               = ["10.1.0.0/20"]
  private_endpoints_subnet_address_prefix = ["10.1.16.0/24"]

  tags = local.tags
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  log_retention_days    = 30
  alert_email_addresses = var.alert_email_addresses
  enable_alerts         = false # Disable alerts in dev

  tags = local.tags
}

# Container Registry
module "acr" {
  source = "../../modules/acr"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  sku           = "Standard"
  admin_enabled = true # Enable for dev convenience

  tags = local.tags
}

# Storage (for ML models)
module "storage" {
  source = "../../modules/storage"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  account_tier       = "Standard"
  replication_type   = "LRS"
  enable_versioning  = true

  tags = local.tags
}

# Key Vault
module "keyvault" {
  source = "../../modules/keyvault"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  enable_rbac_authorization  = true
  purge_protection_enabled   = false # Allow purge in dev
  soft_delete_retention_days = 7

  secrets = {
    "api-key"            = var.api_key
    "storage-access-key" = module.storage.primary_access_key
  }

  tags = local.tags
}

# AKS Cluster
module "aks" {
  source = "../../modules/aks"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name

  kubernetes_version  = "1.28"
  system_node_vm_size = "Standard_D2s_v3"
  system_node_count   = 2
  enable_autoscaling  = true
  system_node_min_count = 2
  system_node_max_count = 3

  enable_ml_node_pool = false # Not needed for dev

  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.id

  tags = local.tags
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
