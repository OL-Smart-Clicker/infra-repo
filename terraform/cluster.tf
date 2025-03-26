module "aks_cluster" {
  source               = "../modules/aks-cluster"
  location             = var.location
  cluster_name         = var.cluster_name
  environment          = var.environment
  cluster_admin_groups = var.cluster_admins
  api_access_cidrs     = var.cluster_access_ips
  subnet_id            = azurerm_subnet.aks_subnet.id
}