resource "azurerm_resource_group" "network_rg" {
  name     = "network-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main_vnet" {
  name                = "WVH-VN-1"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "WVH-SB-PB1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "WVH-SB-NO1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "WVH-SB-PRV1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.1.3.0/24"]
}

# DNS Infrastructure ($0.50/month per zone)
resource "azurerm_private_dns_zone" "private_dns" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.network_rg.name
  tags = merge(local.standard_tags, {
    Service  = "Private-DNS"
    Workload = "Infrastructure"
    Backup   = "NotRequired"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_vnet_link" {
  name                  = "aks-dns-link"
  resource_group_name   = azurerm_resource_group.network_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  tags = merge(local.standard_tags, {
    Service  = "DNS-Link"
    Workload = "Infrastructure"
    Backup   = "NotRequired"
  })
}

# Private Endpoint with Cost-Optimized DNS
resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-${local.cosmos_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  subnet_id           = azurerm_subnet.aks_subnet.id
  private_dns_zone_group {
    name = "privatelink-documents-azure-com"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.private_dns.id
    ]
  }
  private_service_connection {
    name                           = "cosmos-private-link"
    private_connection_resource_id = azurerm_cosmosdb_account.vwh_cosmosdb.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }
  tags = {
    Environment = var.environment
  }
}