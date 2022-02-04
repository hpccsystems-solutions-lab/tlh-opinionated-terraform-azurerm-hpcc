variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "blob-csi-driver" {
  description = "Determines if the blob-csi-drivers are to be installed for the cluster."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to be applied to cloud resources."
  type        = map(string)
  default     = {}
}

# HPCC Storage Config

variable "storage_account_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

variable "storage_account_delete_protection" {
  description = "Protect storage from deletion"
  type        = bool
  default     = true
}

variable "storage_network_subnet_ids" {
  description = "The network ids to grant storage access"
  type        = list(string)
  default     = null
}

# HPCC Config
variable "hpcc_helm_version" {
  description = "Version of the HPCC Helm Chart to use"
  type        = string
  default     = "8.4.12"
}

variable "hpcc_image_root" {
  description = "HPCC Image Root"
  type        = string
  default     = ""
}

variable "hpcc_image_name" {
  description = "HPCC Image Name"
  type        = string
  default     = ""
}

variable "hpcc_namespace" {
  description = "HPCC Namespace"
  type        = string
  default     = "hpcc"
}

variable "hpcc_storage_account_name" {
  description = "Storage account name for hpcc"
  type        = string
  default     = ""
}

variable "hpcc_storage_account_resource_group_name" {
  description = "Storage account resource group name for hpcc"
  type        = string
  default     = ""
}

variable "hpcc_storage_config" {
  description = "Storage config for hpcc"
  type = map(object({
    container_name = string
    size           = string
    })
  )
}

variable "hpcc_replica_config" {
  description = "HPCC component scaling"
  type        = map(number)
  default     = {}
}

/* Future feature
variable "hpcc_disabled_services" {
  description = "HPCC disable services"
  type = map(bool)
  default = {}
}
*/

variable "aks_principal_id" {
  description = "AKS Principal ID"
  type        = string
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

variable "values" {
  type        = any
  default     = {}
  description = "Map of values to pass to helm. Values will be merged"
}