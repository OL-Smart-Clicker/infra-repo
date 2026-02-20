terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  features {}

  # client_secret should be set via environment variable ARM_CLIENT_SECRET for security
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  use_oidc        = var.environment == "production" ? false : true
  client_id       = var.environment == "production" ? "8f245a8e-4ba3-47cb-b268-58cb6c5ec9d6" : null

}
