variable "environment" {
  description = "The Azure tenant environment"
  type        = string
  default     = "staging"
  validation {
    condition     = var.environment == "staging" || var.environment == "production"
    error_message = "Invalid value for environment. Allowed values are staging, production"
  }
}

variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "West Europe"
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "auto_upgrade" {
  description = "The automatic upgrade channel"
  type        = string
  default     = "none"
  validation {
    condition     = var.auto_upgrade == "none" || var.auto_upgrade == "patch" || var.auto_upgrade == "rapid" || var.auto_upgrade == "node-image" || var.auto_upgrade == "stable"
    error_message = "Invalid value for auto_upgrade. Allowed values are none, patch, rapid, node-image, stable"
  }
}

variable "api_access_cidrs" {
  description = "The list of IP ranges that can access the AKS cluster's API server"
  type        = list(string)
  default     = []
  # Regex to validate CIDR
  validation {
    condition     = alltrue([for cidr in var.api_access_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Invalid CIDR format"
  }
}

variable "cluster_admin_groups" {
  description = "The list of EntraID user Group IDs that will have admin access to the cluster"
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "The subnet ID that default AKS nodes will be deployed into"
  type        = string
}

variable "enable_gatekeeper" {
  description = "Enable Azure Policy for AKS - OPA Gatekeeper"
  type        = bool
  default     = false
}

variable "k8s_version" {
  description = "The version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.31.6"
}
