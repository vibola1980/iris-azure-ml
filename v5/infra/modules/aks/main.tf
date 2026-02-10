# ============================================
# Azure Kubernetes Service (AKS) Module
# Enterprise-ready AKS cluster for ML workloads
# ============================================

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # System node pool
  default_node_pool {
    name                = "system"
    vm_size             = var.system_node_vm_size
    node_count          = var.system_node_count
    vnet_subnet_id      = var.subnet_id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = var.enable_autoscaling
    min_count           = var.enable_autoscaling ? var.system_node_min_count : null
    max_count           = var.enable_autoscaling ? var.system_node_max_count : null

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    tags = var.tags
  }

  # Managed identity for AKS
  identity {
    type = "SystemAssigned"
  }

  # Network configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # Azure AD RBAC (optional)
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_rbac ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Key Vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # OMS Agent for monitoring
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

# ML workload node pool (optional)
resource "azurerm_kubernetes_cluster_node_pool" "ml" {
  count = var.enable_ml_node_pool ? 1 : 0

  name                  = "ml"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.ml_node_vm_size
  node_count            = var.ml_node_count
  vnet_subnet_id        = var.subnet_id
  enable_auto_scaling   = var.enable_autoscaling
  min_count             = var.enable_autoscaling ? var.ml_node_min_count : null
  max_count             = var.enable_autoscaling ? var.ml_node_max_count : null

  node_labels = {
    "nodepool-type" = "ml"
    "environment"   = var.environment
    "workload"      = "inference"
  }

  node_taints = var.ml_node_taints

  tags = var.tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "acr_pull" {
  count = var.enable_acr_integration ? 1 : 0

  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
