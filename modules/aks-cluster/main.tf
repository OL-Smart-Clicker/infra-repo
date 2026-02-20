resource "azurerm_resource_group" "cluster_rg" {
  name     = "${var.cluster_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "vwh_aks_cluster" {
  # =================
  # Mandatory:
  # =================

  name                = "${var.cluster_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.cluster_rg.name
  dns_prefix          = "${var.cluster_name}-${var.environment}"
  sku_tier            = "Free"

  default_node_pool {
    name                         = "default"
    node_count                   = 1
    vm_size                      = "Standard_D2s_v4" # 8 GB RAM, 2 vCPU, $83.95/month
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = true # tainting the nodes with CriticalAddonsOnly=true:NoSchedule to avoid scheduling workloads on the system node pool
    temporary_name_for_rotation  = "tempnodepool"
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
    node_labels = {
      "nodetype" = "on-demand"
    }
    tags = merge(local.aks_tags, {
      NodeType = "on-demand"
      Purpose  = "system-workloads"
    })
  }

  # =================
  # Optional:
  # =================

  # Automatic kubernetes version upgrade
  # automatic_upgrade_channel = var.auto_upgrade

  # API access CIDR whitelist
  api_server_access_profile {
    authorized_ip_ranges = var.api_access_cidrs
  }

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.cluster_admin_groups
    azure_rbac_enabled     = true
  }
  # Disable local account for AKS and rely ONLY on Azure AD
  local_account_disabled = true

  # Azure LB tier
  # load_balancer_sku = var.lb_sku

  # Enable Azure Policy for AKS - OPA Gatekeeper
  azure_policy_enabled = var.enable_gatekeeper

  # ingress_application_gateway - (Optional) Configuration block for Application Gateway Ingress Controller.
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "60m"
  }

  kubernetes_version = var.k8s_version

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
    ip_versions         = ["IPv4"]
    /* Not needed currently - expensive
    outbound_type       = "managedNATGateway"
    nat_gateway_profile {
      idle_timeout_in_minutes   = 4
      managed_outbound_ip_count = 1
    }
    */
  }

  oidc_issuer_enabled       = true # Enable OIDC for AKS - needed for EntraID integration
  workload_identity_enabled = true # Allows in-cluster workloads to use Azure AD identities

  # service_mesh_profile { # -- Optional - Service Mesh configuration block. Requires potent node pool.
  #   mode                             = "Istio"
  #   internal_ingress_gateway_enabled = false
  #   external_ingress_gateway_enabled = true
  #   revisions                        = ["asm-1-24"] # Canary Updates
  # }

  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = false
  }

  tags = {
    "environment" = "${var.environment}"
    "cluster"     = "${var.cluster_name}-${var.environment}"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "spot_pool" {
  name                        = "userpool"
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.vwh_aks_cluster.id
  vm_size                     = "Standard_B2pls_v2" # Burstable, cheap instance
  vnet_subnet_id              = var.subnet_id
  auto_scaling_enabled        = true
  min_count                   = 0 # Scale down to 0 after hours
  max_count                   = 2 # Allow up to 2 instances during peak (quota)
  mode                        = "User"
  temporary_name_for_rotation = "tempuserpool"
  priority                    = "Spot"   # Use Spot Instances for cost savings
  eviction_policy             = "Delete" # Auto-delete when reclaimed
  spot_max_price              = -1       # Do not exceed On-Demand pricing

  node_labels = {
    "nodetype" = "spot"
  }

  lifecycle { # Azure will change these automatically
    ignore_changes = [
      node_labels,
      node_taints,
      tags
    ]
  }

  tags = merge(local.aks_tags, {
    NodeType = "spot"
    Purpose  = "user-workloads"
  })
}

resource "azurerm_kubernetes_cluster_node_pool" "non_spot_pool" {
  name                        = "userpooldmd"
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.vwh_aks_cluster.id
  vm_size                     = "Standard_B2pls_v2" # Burstable, cheap instance
  vnet_subnet_id              = var.subnet_id
  auto_scaling_enabled        = true
  min_count                   = 0 # Scale down to 0 after hours
  max_count                   = 2 # Allow up to 2 instances during peak (quota)
  mode                        = "User"
  temporary_name_for_rotation = "tempusrpoo1"

  node_labels = {
    "nodetype" = "on-demand"
  }

  lifecycle { # Azure will change these automatically
    ignore_changes = [
      node_labels,
      node_taints,
      tags
    ]
  }

  tags = merge(local.aks_tags, {
    NodeType = "spot"
    Purpose  = "user-workloads"
  })
}
