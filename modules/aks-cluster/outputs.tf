output "aks_irsa_uuid" {
  value = azurerm_user_assigned_identity.aks_irsa.principal_id
}

output "aks_irsa_clientid" {
  value = azurerm_user_assigned_identity.aks_irsa.client_id
}

output "cluster_identity" {
  value = azurerm_kubernetes_cluster.vwh_aks_cluster.kubelet_identity[0].object_id
}

output "cluster_rg" {
  value = azurerm_resource_group.cluster_rg.name
}