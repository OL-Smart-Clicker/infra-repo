terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate-${lower(var.env)}-sa" # Must be globally unique
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    # access_key = "${ARM_ACCESS_KEY}" # Set via env var instead
  }
}
