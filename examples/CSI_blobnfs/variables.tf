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

variable "hpcc_image_root" {
  description = "HPCC Helm image root"
  type        = string
}

variable "hpcc_image_name" {
  description = "HPCC Helm image name"
  type        = string
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