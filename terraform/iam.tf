# Allow AKS (backend) to read from CosmosDB
resource "azurerm_cosmosdb_sql_role_assignment" "aks_to_cosmosdb_read_role" {
  resource_group_name = azurerm_resource_group.data_rg.name
  account_name        = azurerm_cosmosdb_account.vwh_cosmosdb.name
  # CosmosDB reader (R)
  role_definition_id = "${azurerm_cosmosdb_account.vwh_cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001"
  principal_id       = module.aks_cluster.aks_irsa_uuid
  scope              = azurerm_cosmosdb_account.vwh_cosmosdb.id
}

# Allow AKS (backend) R/W access to Storage Account
resource "azurerm_role_assignment" "aks_storage_access" {
  scope                = azurerm_storage_account.wvh_photo_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks_cluster.aks_irsa_uuid
}

# Allow IoT Hub to write to CosmosDB
resource "azurerm_cosmosdb_sql_role_assignment" "iothub_to_cosmosdb_role" {
  resource_group_name = azurerm_resource_group.data_rg.name
  account_name        = azurerm_cosmosdb_account.vwh_cosmosdb.name
  # CosmosDB contributor (R+W)
  role_definition_id = "${azurerm_cosmosdb_account.vwh_cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id       = azurerm_iothub.vwh_iothub.identity[0].principal_id
  scope              = azurerm_cosmosdb_account.vwh_cosmosdb.id
}