variable "address_space" {
  description = "List of address spaces"
  type        = list(string)
}

variable "core_services_config" {
  description = "cluster config"
  type        = any
  default     = {}
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users  = map(string)
      cluster_view_users   = map(string)
      standard_view_users  = map(string)
      standard_view_groups = map(string)
    }
  )
  default = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

variable "api_server_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

variable "storage_account_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

variable "hpcc_storage_config" {
  description = "Storage config for hpcc"
  type = map(object({
    container_name = string
    size           = string
    })
  )
}

variable "hpcc_helm_version" {
  description = "HPCC Helm Version"
  type        = string
}

variable "private_cidrs" {
  description = "Private AKS cidrs"
  type        = list(string)
}

variable "public_cidrs" {
  description = "Public AKS cidrs"
  type        = list(string)
}

variable "service_endpoints" {
  description = "Creates a virtual network rule in the subnet_id (values are virtual network subnet ids)."
  type        = map(string)
  default     = {}
}

# Admin Subnets
variable "azure_admin_subnets" {
  description = "Azure Admin Subnets (for service endpoints)"
  type        = map(string)
  default     = {}
}

# JFrog
variable "jfrog_registry" {
  description = "values to set as secrets for JFrog repo access"
  type = object({
    username   = string
    password   = string # API Token
    image_root = string
    image_name = string
  })
  sensitive = true
}

variable "hpc_cache_enabled" {
  description = "Creates the hpc-cache for the cluster."
  type        = bool
  default     = false
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

variable "thor_workers" {
  type = number
}

variable "thor_maxvalues" {
  type = object({
    maxJobs   = number
    maxGraphs = number
  })
}