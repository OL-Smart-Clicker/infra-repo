output "iothub_hostname" {
  value = azurerm_iothub.vwh_iothub.hostname
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.vwh_cosmosdb.endpoint
}

output "private_endpoint_fqdn" {
  value = "${azurerm_cosmosdb_account.vwh_cosmosdb.name}.privatelink.documents.azure.com"
}
