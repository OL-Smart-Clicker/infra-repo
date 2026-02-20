resource "null_resource" "aks_auth" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.cluster_rg.name} --name ${azurerm_kubernetes_cluster.vwh_aks_cluster.name} --overwrite-existing"
  }
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}