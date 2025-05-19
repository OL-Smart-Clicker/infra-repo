data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "wvh-aks-kv" {
  name                       = "wvh-aks-kv-${var.environment}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.cluster_rg.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "staging" ? false : true
}