
#variable "cache_update_frequency" {
#  description = "HPC Cache target update frequency."
#
#  validation {
#    condition     = contains(["never", "30s", "3h"], var.cache_update_frequency)
#    error_message = "HPC Cache target update frequency must be \"never\", \"30s\" or \"3h\"."
#  }
#}

variable "dns" {
  description = "DNS info for HPC Cache."
  type = object({
    zone_name                = string
    zone_resource_group_name = string
  })
}

variable "location" {
  description = "Azure region in which to create resources."
  type        = string
}

variable "name" {
  description = "HPC Cache name."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources."
  type        = string
}

variable "resource_provider_object_id" {
  description = "Object ID for HPC Cache Resource Provider."
  type        = string
}

variable "size" {
  description = "HPC Cache size."
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "HPC Cache size must be \"small\", \"medium\" or \"large\"."
  }
}

variable "storage_targets" {
  description = "Storage target information."
  type = map(object({
    cache_update_frequency = string
    storage_account_data_planes = list(object({
      container_id         = string
      container_name       = string
      id                   = number
      resource_group_name  = string
      storage_account_id   = string
      storage_account_name = string
    }))
  }))
}

variable "subnet_id" {
  description = "Subnet ID in which HPC Cache will be created."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to Azure resources."
  type        = map(string)
  default     = {}
}