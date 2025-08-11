# Production Environment Configuration
environment     = "prod"
location        = "West Europe"
subscription_id = "00f6ce61-2fe9-4e23-b6a9-c2f1c2a4b1f0"
tenant_id       = "a72d5a72-25ee-40f0-9bd1-067cb5b770d4"

# AKS cluster config
cluster_name = "wvh-aks-cluster"

# Security - Add your specific IP addresses and admin groups
cluster_access_ips = [
  # Add your office/admin IP addresses here
  # "YOUR.OFFICE.IP.ADDRESS/32",
  "86.120.249.85/32", # Mario
]

cluster_admins = [
  # Add Azure AD Group IDs for production administrators
  # "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
]

# Production configuration
cluster_lb_sku = "standard"
cosmos_tier    = "Standard"

# Custom tags for this client environment
additional_tags = {
  Client      = "New-Client"
  Environment = "production"
  CostCenter  = "Client-Production"
  Contact     = "client-admin@company.com"
}
