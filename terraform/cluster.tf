module "aks_cluster" {
  source         = "../modules/aks-cluster"
  location       = var.location
  cluster_name   = "vwh-aks-cluster"
  cluster_admins = var.cluster_admins
}