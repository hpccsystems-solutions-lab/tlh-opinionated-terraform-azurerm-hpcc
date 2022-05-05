variable "container_name" {
  description = "Name of container to create within storage accounts."
  type        = string
  default     = "hpcc-data"
}

variable "data_plane_count" {
  description = "Number of data planes/storage accounts to be created."
  type        = number
  default     = 1
}

variable "location" {
  description = "Azure region in which to create resources."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources."
  type        = string
}

variable "storage_account_name_prefix" {
  description = "Prefix for storage account name (leave null for auto-generation)."
  type        = string
}

variable "storage_account_settings" {
  description = "Settings storage accounts."
  type = object({
    authorized_ip_ranges = map(string)
    delete_protection    = bool
    replication_type     = string
    subnet_ids           = map(string)
  })
  default = {
    authorized_ip_ranges = {}
    delete_protection    = false
    replication_type     = "ZRS"
    subnet_ids           = {}
  }
}

variable "tags" {
  description = "Tags to be applied to Azure resources."
  type        = map(string)
  default     = {}
}
