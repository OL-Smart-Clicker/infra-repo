locals {
  k8s_namespace = "backend"
  sa_name       = "backend-sa"
}

resource "azurerm_user_assigned_identity" "aks_irsa" {
  name                = "${var.cluster_name}-irsa"
  location            = azurerm_resource_group.cluster_rg.location
  resource_group_name = azurerm_resource_group.cluster_rg.name

  tags = {
    "environment" = "staging"
    "cluster"     = "${var.cluster_name}-${var.environment}"
  }
}

resource "azurerm_federated_identity_credential" "irsa_federation" {
  name                = "${var.cluster_name}-irsa-federation"
  resource_group_name = azurerm_resource_group.cluster_rg.name
  parent_id           = azurerm_user_assigned_identity.aks_irsa.id
  issuer              = azurerm_kubernetes_cluster.vwh_aks_cluster.oidc_issuer_url
  subject             = "system:serviceaccount:${local.k8s_namespace}:${local.sa_name}"
  audience            = ["api://AzureADTokenExchange"]
}
