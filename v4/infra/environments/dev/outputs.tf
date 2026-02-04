# ============================================
# Development Environment - Outputs
# ============================================

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_kube_config" {
  description = "Kubernetes config"
  value       = module.aks.kube_config
  sensitive   = true
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.acr.login_server
}

output "acr_name" {
  description = "ACR name"
  value       = module.acr.name
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.name
}

output "storage_blob_endpoint" {
  description = "Blob storage endpoint"
  value       = module.storage.primary_blob_endpoint
}

output "keyvault_name" {
  description = "Key Vault name"
  value       = module.keyvault.name
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}
