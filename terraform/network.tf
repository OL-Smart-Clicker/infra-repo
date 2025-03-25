resource "azurerm_resource_group" "network_rg" {
  name     = "network-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main_vnet" {
  name                = "WVH-VN-1"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "WVH-SB-PB1"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "WVH-SB-NO1"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "WVH-SB-PRV1"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.1.3.0/24"]
}
