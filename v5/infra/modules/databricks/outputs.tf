# ============================================
# Databricks Module - Outputs
# ============================================

output "workspace_id" {
  description = "Databricks workspace ID"
  value       = azurerm_databricks_workspace.main.id
}

output "workspace_url" {
  description = "Databricks workspace URL"
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "workspace_name" {
  description = "Databricks workspace name"
  value       = azurerm_databricks_workspace.main.name
}

output "access_connector_id" {
  description = "Access Connector ID"
  value       = azurerm_databricks_access_connector.main.id
}

output "access_connector_identity" {
  description = "Access Connector managed identity principal ID"
  value       = azurerm_databricks_access_connector.main.identity[0].principal_id
}
