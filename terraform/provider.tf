terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.107" # Pin AzureRM provider version
    }
  }
}

# Configure default provider
provider "azurerm" {
  features {}

#   client_id       = var.client_id  
#   client_secret   = var.client_secret
#   tenant_id       = var.tenant_id
#   subscription_id = var.subscription_id

   client_id       =   
   client_secret   = 
   tenant_id       = 
   subscription_id = 

}
