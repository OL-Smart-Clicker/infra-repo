variable "environment" {
  description = "The environment in which the resources will be deployed"
  type        = string
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