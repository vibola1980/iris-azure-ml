# ============================================
# Storage Module Outputs
# ============================================

output "id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "models_container_name" {
  description = "Models container name"
  value       = azurerm_storage_container.models.name
}
