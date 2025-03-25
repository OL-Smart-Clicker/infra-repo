resource "azurerm_resource_group" "cluster_rg" {
  name     = "${var.cluster_name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  # =================
  # Mandatory:
  # =================

  name                = "wvh-aks-cluster"
  location            = var.location
  resource_group_name = var.cluster_rg
  dns_prefix          = "wvh-aks-cluster"
  sku_tier            = "Free"

  default_node_pool {
    name                  = "default"
    vm_size               = "Standard_B2ms" # Standard_B2ms is the minimum size for AKS
    enable_auto_scaling   = true
    min_count             = 1
    max_count             = 5
    vnet_subnet_id        = azurerm_subnet.aks_subnet.id
    max_pods              = 50 # Maximum number of pods per node
    os_disk_size_gb       = 128
    type                  = "VirtualMachineScaleSets"
    enable_node_public_ip = false
    ultra_ssd_enabled     = false

    # SPOT configuration
    priority        = "Spot"
    eviction_policy = "Delete"
    spot_max_price  = -1 # Will not exceed on-demand cost

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "staging"
    }
    tags = {
      "Environment" = "Staging"
      "Cluster"     = "wvh-aks-cluster"
    }
  }

  # =================
  # Optional:
  # =================

  # Automatic kubernetes version upgrade
  automatic_upgrade_channel = var.auto_upgrade

  # API access CIDR whitelist
  api_server_access_profile {
    authorized_ip_ranges = var.api_access_cidrs
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true # Balance the number of nodes accross zones
    expander                         = "least-waste"
    max_node_provisioning_time       = "15m"
    scale_down_delay_after_add       = "5m"
    scale_down_utilization_threshold = 0.4 # At 40% utilization - agressive
  }

  azure_active_directory_role_based_access_control {
    managed                = true # Leverage Azure AD for RBAC
    admin_group_object_ids = var.cluster_admins
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

  #   node_auto_provisioning {
  #     enabled = true
  #     spot_instances {
  #       enabled = true
  #     }
  #   }
  oidc_issuer_enabled       = true # Enable OIDC for AKS - needed for EntraID integration
  open_service_mesh_enabled = true # Advanced network security features

  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  tags = {
    "Environment" = "Staging"
    "Cluster"     = "wvh-aks-cluster"
  }
}
