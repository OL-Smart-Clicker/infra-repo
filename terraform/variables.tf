variable "environment" {
  description = "Deployment environment (staging/production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], lower(var.environment))
    error_message = "Environment must be 'staging' or 'production'."
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

# IoT Hub
variable "iot_allowed_ips" {
  description = "Allowed IP ranges for IoT Hub"
  type        = list(string)
  default     = []
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