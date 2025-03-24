terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}

  # OIDC authentication with Azure DevOps service connection
  use_oidc        = true
  subscription_id = "c2de087f-ee03-4605-96bc-44a2338c298f"
  tenant_id       = "3cb226f3-72b0-447d-b57d-31f479808bad"
}
