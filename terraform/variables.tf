variable "env" {
  description = "The environment in which the resources will be deployed"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "West Europe"
}