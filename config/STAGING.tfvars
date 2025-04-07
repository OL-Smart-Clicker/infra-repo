environment = "staging"
location    = "West Europe"

# AKS cluster config
cluster_name = "vwh-aks-cluster"
cluster_access_ips = [
  "145.93.117.3/32" # Mario LAN
]
cluster_admins = [
  "7f1ecc8d-962c-4ca0-85a9-9c11386a5f80" # AKS Admins
]

cluster_lb_sku = "bsic"
