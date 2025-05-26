output "iothub_hostname" {
  value = azurerm_iothub.vwh_iothub.hostname
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.vwh_cosmosdb.endpoint
}

output "private_endpoint_fqdn" {
  value = "${azurerm_cosmosdb_account.vwh_cosmosdb.name}.privatelink.documents.azure.com"
}

output "aks_irsa_clientid" {
  value = module.aks_cluster.aks_irsa_clientid
}

output "acr_username" {
  description = "The Username of the Azure Container Registry"
  value       = azurerm_container_registry.wvh_acr.admin_username
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.wvh_acr.login_server
}

output "dps_id_scope" {
  description = "The unique identifier of the IoT Device Provisioning Service (ID Scope) needed by devices."
  value       = azurerm_iothub_dps.wvh_iothub_dps.id_scope
}

output "dps_device_provisioning_host_name" {
  description = "The device endpoint of the IoT Device Provisioning Service needed by devices."
  value       = azurerm_iothub_dps.wvh_iothub_dps.device_provisioning_host_name
}
