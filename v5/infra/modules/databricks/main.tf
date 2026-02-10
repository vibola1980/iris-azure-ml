# ============================================
# Databricks Module
# Workspace + Access Connector + RBAC
# ============================================

# Access Connector for Unity Catalog / external storage
resource "azurerm_databricks_access_connector" "main" {
  name                = "dbac-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Databricks Workspace
resource "azurerm_databricks_workspace" "main" {
  name                = "dbw-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  tags = var.tags
}

# Grant Access Connector read/write to Blob Storage (for model export)
resource "azurerm_role_assignment" "databricks_storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.main.identity[0].principal_id
}
