resource "azurerm_resource_group" "cluster_rg" {
  name     = "${var.cluster_name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
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
    vm_size                      = "Standard_DS1_v2" # 3.5 GB RAM, 1 vCPU
    only_critical_addons_enabled = true              # tainting the nodes with CriticalAddonsOnly=true:NoSchedule to avoid scheduling workloads on the system node pool
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
    node_labels = {
      "nodetype" = "on-demand"
    }
    tags = {
      "environment" = "staging"
      "cluster"     = "${var.cluster_name}-${var.environment}"
    }
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
    # tenant_id              = "<your-tenant-id>"  # Optional, if different from current subscription
  }
  local_account_disabled = true # Disable local account for AKS and rely on Azure AD

  # Enable Azure Policy for AKS - OPA Gatekeeper
  azure_policy_enabled = var.enable_gatekeeper

  # ingress_application_gateway - (Optional) Configuration block for Application Gateway Ingress Controller.
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "5m"
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
    /* Not needed for Staging - expenisve
    outbound_type       = "managedNATGateway"
    nat_gateway_profile {
      idle_timeout_in_minutes   = 4
      managed_outbound_ip_count = 1
    }
    */
  }

  oidc_issuer_enabled = true # Enable OIDC for AKS - needed for EntraID integration

  service_mesh_profile {
    mode                             = "Istio"
    internal_ingress_gateway_enabled = false
    external_ingress_gateway_enabled = true
    revisions                        = ["asm-1-20"] # Canary Updates
  }

  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  tags = {
    "environment" = "staging"
    "cluster"     = "wvh-aks-cluster"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "spot_pool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = "Standard_B2s" # Burstable, cheap instance
  auto_scaling_enabled  = true
  min_count             = 0 # Scale down to 0 after hours
  max_count             = 3 # Allow up to 3 instances during peak
  mode                  = "User"

  priority        = "Spot"   # Use Spot Instances for cost savings
  eviction_policy = "Delete" # Auto-delete when reclaimed
  spot_max_price  = -1       # Do not exceed On-Demand pricing

  node_labels = {
    "nodetype" = "spot"
  }

  tags = {
    "environment" = "staging"
  }
}
