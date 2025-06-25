resource "azurerm_storage_account" "wvh_photo_storage" {
  name                            = "wvhphotostorage"
  resource_group_name             = azurerm_resource_group.data_rg.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Networking
  public_network_access_enabled = false
  min_tls_version               = "TLS1_2"
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.aks_subnet.id]
  }

  tags = merge(local.standard_tags, {
    Service   = "StorageAccount"
    Workload  = "Photo-Storage"
    DataClass = "Internal"
  })
}