variable "hpcc_storage_config" {
  description = "Storage config for hpcc"
  type = map(
    object({
      container_name = string
      size           = string
    })
  )
}

variable "hpcc_storage_account_name" {
  description = "Storage account name for hpcc"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "storage_account_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

variable "storage_network_subnet_ids" {
  description = "The network ids to grant storage access"
  type        = list(string)
  default     = null
}

variable "storage_account_delete_protection" {
  description = "Protect storage from deletion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to be applied to cloud resources."
  type        = map(string)
  default     = {}
}

variable "hpcc_namespace" {
  description = "HPCC Namespace"
  type        = string
  default     = "hpcc"
}

# HPC Cache Resource Provider object_id
variable "object_id" {
  type    = string
  default = "d76481b9-94f9-4ce5-b322-e24b3c1646f0"
}

variable "hpc_cache_dns_name" {
  type = object({
    zone_name                = string
    zone_resource_group_name = string
  })
}

variable "hpc_cache_name" {
  type = string
}