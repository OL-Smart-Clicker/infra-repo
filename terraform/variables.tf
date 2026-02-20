variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Invalid Subscription ID format."
  }
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Invalid Tenant ID format."
  }
}

variable "environment" {
  description = "Deployment environment (staging/prod)"
  type        = string
  validation {
    condition     = contains(["staging", "prod"], lower(var.environment))
    error_message = "Environment must be 'staging' or 'prod'."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "cluster_admins" {
  description = "The list of EntraID user Group IDs that will have admin access to the cluster"
  type        = list(string)
  default     = []
}

variable "cluster_access_ips" {
  description = "The list of IP ranges that can access the AKS cluster's API server"
  type        = list(string)
  default     = []
  # Regex to validate CIDR
  validation {
    condition     = alltrue([for cidr in var.cluster_access_ips : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Invalid CIDR format"
  }
}

variable "cluster_lb_sku" {
  description = "The SKU of the AKS cluster LB. Valid values are 'basic' and 'standard'"
  type        = string
  default     = "standard"
}

# CosmosDB
variable "cosmos_tier" {
  description = "Cosmos DB pricing tier (Free/Standard)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], title(var.cosmos_tier))
    error_message = "Must be 'Free' or 'Standard'."
  }
}

# Common tags for all resources
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "Smart-Clicker"
    Owner       = "OL-Team"
    ManagedBy   = "Terraform"
    Repository  = "infra-repo"
    CreatedDate = "2025-06-18"
  }
}

variable "additional_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}

locals {
  # Merge common tags with environment-specific and additional tags
  standard_tags = merge(
    var.common_tags,
    {
      Environment  = var.environment
      CostCenter   = var.environment == "staging" ? "Development" : "Production"
      CostPolicy   = var.environment == "staging" ? "FreeTier" : "Production"
      LastModified = formatdate("YYYY-MM-DD", timestamp())
    },
    var.additional_tags
  )
}