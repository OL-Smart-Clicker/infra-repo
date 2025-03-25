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
  description = "The list of IP ranges that can access the API server"
  type        = list(string)
  default     = []
  # Regex to validate CIDR
  validation {
    condition     = alltrue([for cidr in var.api_access_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Invalid CIDR format"
  }
}

variable "cluster_admins" {
  description = "The list of users that will have admin access to the cluster"
  type        = list(string)
  default     = []
}

variable "enable_gatekeeper" {
  description = "Enable Azure Policy for AKS - OPA Gatekeeper"
  type        = bool
  default     = false
}

variable "k8s_version" {
  description = "The version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.32.2"
} 