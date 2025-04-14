output "iothub_hostname" {
  value = azurerm_iothub.vwh_iothub.hostname
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.vwh_cosmosdb.endpoint
}

output "private_endpoint_fqdn" {
  value = "${azurerm_cosmosdb_account.vwh_cosmosdb.name}.privatelink.documents.azure.com"
}

output "aks_irsa_id" {
  value = module.aks_cluster.aks_irsa_id
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.wvh_acr.id
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.wvh_acr.login_server
}