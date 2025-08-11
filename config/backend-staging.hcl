# Staging Environment Backend Configuration
resource_group_name  = "tfstate-rg"
storage_account_name = "wvhtfstatesa"
container_name       = "tfstate-staging"
key                  = "staging/terraform.tfstate"
