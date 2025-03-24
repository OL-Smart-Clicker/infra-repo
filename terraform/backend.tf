terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "wvhtfstatesa"
    container_name       = "staging"
    key                  = "terraform.tfstate"
  }
}
