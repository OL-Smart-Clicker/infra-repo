locals {
  iothub_sku  = var.environment == "staging" ? "F1" : "S1"
  iothub_name = lower("wvh-iothub-${var.environment}")
}

resource "azurerm_resource_group" "data_rg" {
  name     = lower("wvh-data-rg-${var.environment}")
  location = var.location
}

# IoT Hub with Conditional Free Tier
resource "azurerm_iothub" "vwh_iothub" {
  name                = local.iothub_name
  resource_group_name = azurerm_resource_group.data_rg.name
  location            = var.location

  sku {
    name     = local.iothub_sku
    capacity = var.environment == "staging" ? 1 : 2
  }

  identity {
    type = "SystemAssigned"
  }

  # enrichment -- optional, data transformation

  public_network_access_enabled = true

  # Must be set for free tier (MAX 2 partitions)
  event_hub_partition_count = var.environment == "staging" ? 2 : null

  # Network security configuration
  network_rule_set {
    default_action                     = "Deny"
    apply_to_builtin_eventhub_endpoint = false

    dynamic "ip_rule" {
      for_each = var.iot_allowed_ips
      content {
        name    = "allow_${ip_rule.key}"
        ip_mask = ip_rule.value
        action  = "Allow"
      }
    }
  }

  tags = {
    CostCenter  = "Staging"
    Environment = var.environment
  }
}

# IoT Hub Endpoint for CosmosDB
resource "azurerm_iothub_endpoint_cosmosdb_account" "iothub_cosmosdb_endpoint" {
  name                   = "IoTCosmosDBEndpoint"
  resource_group_name    = azurerm_resource_group.data_rg.name
  iothub_id              = azurerm_iothub.vwh_iothub.id
  container_name         = "clicker-data"
  database_name          = "wvh-cosmosdb"
  partition_key_name     = "/officeID"
  partition_key_template = "/officeID"
  endpoint_uri           = azurerm_cosmosdb_account.vwh_cosmosdb.endpoint
  authentication_type    = "identityBased"
}

# Route for IoT Hub to CosmosDB
resource "azurerm_iothub_route" "iot-cosmosdb-route" {
  resource_group_name = azurerm_resource_group.data_rg.name
  iothub_name         = azurerm_iothub.vwh_iothub.name
  name                = "cosmosdb-route"

  source         = "DeviceMessages"
  condition      = "true" # Route all device messages
  endpoint_names = [azurerm_iothub_endpoint_cosmosdb_account.iothub_cosmosdb_endpoint.name]
  enabled        = true
}

# Allow IoT Hub to write to CosmosDB - identityBased authentication
resource "azurerm_cosmosdb_sql_role_assignment" "iothub_to_cosmosdb_role" {
  resource_group_name = azurerm_resource_group.data_rg.name
  account_name        = azurerm_cosmosdb_account.vwh_cosmosdb.name
  # CosmosDB contributor
  role_definition_id = "${azurerm_cosmosdb_account.vwh_cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id       = azurerm_iothub.vwh_iothub.identity[0].principal_id
  scope              = azurerm_cosmosdb_account.vwh_cosmosdb.id
}