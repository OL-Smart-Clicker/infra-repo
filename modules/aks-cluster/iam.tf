locals {
  k8s_namespace = "backend"
  sa_name       = "backend-sa"
}

resource "azurerm_user_assigned_identity" "aks_irsa" {
  name                = "${var.cluster_name}--${var.environment}-irsa"
  location            = azurerm_resource_group.cluster_rg.location
  resource_group_name = azurerm_resource_group.cluster_rg.name

  tags = {
    "environment" = "${var.environment}"
    "cluster"     = "${var.cluster_name}-${var.environment}"
  }
}

resource "azurerm_federated_identity_credential" "irsa_federation" {
  name                = "${var.cluster_name}-${var.environment}-irsa-federation"
  resource_group_name = azurerm_resource_group.cluster_rg.name
  parent_id           = azurerm_user_assigned_identity.aks_irsa.id
  issuer              = azurerm_kubernetes_cluster.vwh_aks_cluster.oidc_issuer_url
  # system:serviceaccount:backend:backend-sa"
  subject  = "system:serviceaccount:${local.k8s_namespace}:${local.sa_name}"
  audience = ["api://AzureADTokenExchange"]
}

# Allow the Key Vault Secrets Provider to access the Key Vault Secrets
resource "azurerm_role_assignment" "kv_secrets_provider_access" {
  scope                = azurerm_key_vault.wvh-aks-kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.vwh_aks_cluster.key_vault_secrets_provider[0].secret_identity[0].object_id
}
