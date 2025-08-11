resource "azurerm_container_registry" "wvh_acr" {
  name                = "wvhacr${var.environment}"
  resource_group_name = module.aks_cluster.cluster_rg
  location            = var.location
  admin_enabled       = true # Needed to integrate GitHub Actions with ACR
  # Conditional SKU based on environment
  sku = var.environment == "staging" ? "Basic" : "Standard"
  tags = merge(local.standard_tags, {
    Service  = "Container-Registry"
    Workload = "Infrastructure"
    Backup   = "NotRequired"
  })
}

# To retrieve the ACR password for use in CI/CD pipelines, run the following command:
# wsl az acr credential show -n wvhacr<environment> --query "passwords[0].value" -o tsv

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.aks_cluster.cluster_identity
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.wvh_acr.id
  skip_service_principal_aad_check = true
}