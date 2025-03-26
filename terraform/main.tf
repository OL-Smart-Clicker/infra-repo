resource "azurerm_resource_group" "test_rg" {
  name     = "tf-test-rg"
  location = var.location
}