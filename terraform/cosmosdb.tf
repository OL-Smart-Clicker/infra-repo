locals {
  cosmos_consistency = var.environment == "staging" ? "Session" : "BoundedStaleness"
  cosmos_name        = lower("wvh-cosmos-${var.environment}")
  cosmos_region      = "germanywestcentral" # NOT WESTEUROPE - quota issues
}

# Cosmos DB with Free Tier Option
resource "azurerm_cosmosdb_account" "vwh_cosmosdb" {
  # =================
  # Mandatory:
  # =================

  name                = local.cosmos_name
  resource_group_name = azurerm_resource_group.data_rg.name
  location            = local.cosmos_region
  offer_type          = "Standard"

  # =================
  # Optional:
  # =================

  kind = "GlobalDocumentDB"
  consistency_policy {
    consistency_level       = local.cosmos_consistency
    max_interval_in_seconds = var.environment == "staging" ? null : 300
    max_staleness_prefix    = var.environment == "staging" ? null : 100000
  }

  geo_location {
    location          = local.cosmos_region
    failover_priority = 0
  }

  # Conditional geo_location block for production failover
  dynamic "geo_location" {
    for_each = var.environment == "production" ? [1] : []
    content {
      location          = "francecentral"
      failover_priority = 1
      zone_redundant    = false
    }
  }

  free_tier_enabled             = var.environment == "staging" ? true : false
  automatic_failover_enabled    = var.environment == "production" ? true : false
  burst_capacity_enabled        = true
  local_authentication_disabled = true

  capacity {
    total_throughput_limit = var.environment == "production" ? -1 : 100 # Fall within the free tier limit for staging
  }

  # Networking
  public_network_access_enabled = true
  ip_range_filter = [
    "13.91.105.215/32", # AZ Portal 1
    "4.210.172.107/32", # AZ Portal 2
    "13.88.56.148/32",  # AZ Portal 3
    "40.91.218.243/32", # AZ Portal 4
  ]
  network_acl_bypass_for_azure_services = true
  is_virtual_network_filter_enabled     = true
  virtual_network_rule {
    id = azurerm_subnet.aks_subnet.id
  }

  minimal_tls_version = "Tls12" # Enforce TLS 1.2

  lifecycle {
    ignore_changes = [geo_location]
  }

  backup {
    type                = var.environment == "production" ? "Continuous" : "Periodic"
    interval_in_minutes = var.environment == "production" ? "720" : "1440"
    retention_in_hours  = var.environment == "production" ? "48" : "24"
    storage_redundancy  = var.environment == "production" ? "Zone" : "Local"
  }

  tags = {
    CostPolicy  = var.environment == "staging" ? "FreeTier" : "Production"
    Environment = var.environment
  }

}