# ============================================
# Azure Key Vault Module
# Secure secrets management
# ============================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Security settings
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # RBAC authorization
  enable_rbac_authorization = var.enable_rbac_authorization

  # Network rules
  dynamic "network_acls" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = "Deny"
      bypass                     = "AzureServices"
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  tags = var.tags
}

# Grant current user/service principal access (for Terraform operations)
resource "azurerm_key_vault_access_policy" "terraform" {
  count = var.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

# RBAC role assignment for AKS
resource "azurerm_role_assignment" "aks_secrets_user" {
  count = var.enable_rbac_authorization && var.aks_kubelet_identity_id != null ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_kubelet_identity_id
}

# Access policy for AKS (non-RBAC mode)
resource "azurerm_key_vault_access_policy" "aks" {
  count = !var.enable_rbac_authorization && var.aks_kubelet_identity_id != null ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.aks_kubelet_identity_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Store secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform
  ]
}

# Optional: Private endpoint
resource "azurerm_private_endpoint" "keyvault" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "pe-${azurerm_key_vault.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_key_vault.main.name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}
