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
    default_action                     = "Allow" # Allow all IoT Hub devices to connect
    apply_to_builtin_eventhub_endpoint = false

    # dynamic "ip_rule" {
    #   for_each = var.iot_allowed_ips
    #   content {
    #     name    = "allow_${ip_rule.key}"
    #     ip_mask = ip_rule.value
    #     action  = "Allow"
    #   }
    # }
  }
  tags = merge(local.standard_tags, {
    Service   = "IoT-Hub"
    Workload  = "Data-Ingestion"
    DataClass = "Sensor-Data"
    Backup    = "NotRequired"
  })
}

# IoT Hub Endpoint for CosmosDB
resource "azurerm_iothub_endpoint_cosmosdb_account" "iothub_cosmosdb_endpoint" {
  name                   = "IoTCosmosDBEndpoint"
  resource_group_name    = azurerm_resource_group.data_rg.name
  iothub_id              = azurerm_iothub.vwh_iothub.id
  container_name         = azurerm_cosmosdb_sql_container.clicker_data_container.name
  database_name          = azurerm_cosmosdb_sql_database.wvh_db.name
  partition_key_name     = "officeSpaceId"
  partition_key_template = "{deviceid}-{YYYY}-{MM}-{DD}"
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

resource "azurerm_iothub_shared_access_policy" "wvh_iothub_ap" {
  name                = "wvh-iothub-policy"
  resource_group_name = azurerm_resource_group.data_rg.name
  iothub_name         = azurerm_iothub.vwh_iothub.name

  registry_read   = true # List devices
  registry_write  = true # Create devices
  service_connect = true # Connect to the IoT Hub service as app
  device_connect  = true # Connect to the IoT Hub as a device
}

# Device provisioning service (DPS) for IoT Hub
resource "azurerm_iothub_dps" "wvh_iothub_dps" {
  name                = "wvh-iothub-dps-${var.environment}"
  resource_group_name = azurerm_resource_group.data_rg.name
  location            = var.location
  allocation_policy   = "Static"

  sku {
    name     = "S1"
    capacity = "1"
  }

  tags = {
    CostPolicy  = var.environment == "staging" ? "FreeTier" : "Production"
    Environment = var.environment
  }

  linked_hub {
    connection_string = azurerm_iothub_shared_access_policy.wvh_iothub_ap.primary_connection_string
    location          = var.location
  }
}
