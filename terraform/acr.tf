resource "azurerm_container_registry" "wvh_acr" {
  name                = "wvhacr${var.environment}"
  resource_group_name = module.aks_cluster.cluster_rg
  location            = var.location
  # Conditional SKU based on environment
  sku = var.environment == "staging" ? "Basic" : "Standard"
  tags = {
    CostPolicy  = var.environment == "staging" ? "FreeTier" : "Production"
    Environment = var.environment
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.aks_cluster.cluster_identity
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.wvh_acr.id
  skip_service_principal_aad_check = true
}