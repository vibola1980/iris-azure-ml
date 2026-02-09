output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "file_share_name" {
  value = azurerm_storage_share.share.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "aci_fqdn" {
  value = var.deploy_aci ? azurerm_container_group.aci[0].fqdn : "(ACI not deployed yet)"
}

output "predict_url" {
  value = var.deploy_aci ? "http://${azurerm_container_group.aci[0].fqdn}:8000/predict" : "(deploy with -var=deploy_aci=true after pushing image and model)"
}
