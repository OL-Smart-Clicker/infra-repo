resource "azurerm_resource_group" "test_rg" {
  name     = "tf-test-rg"
  location = var.location
}

resource "azurerm_resource_group" "platform_rg" {
  name     = "platform-rg"
  location = var.location
}