variable "dns_zone_name" {
  description = "Azure DNS zone."
  type        = string
}

variable "dns_zone_resource_group" {
  description = "Azure DNS zone resource group."
  type        = string
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

variable "storage_account_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

variable "hpcc_helm_chart_version" {
  description = "HPCC helm chart version"
  type        = string
}

variable "hpcc_container" {
  description = "HPCC container registry info."
  type = object({
    image_name = string
    image_root = string
    version    = string
  })
}

variable "hpcc_container_registry_auth" {
  description = "Registry authentication for HPCC containers."
  type = object({
    password = string
    username = string
  })
  default   = null
  sensitive = true
}