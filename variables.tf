# AKS Config

variable "address_space" {
  description = "The vnet address spaces."
  type        = list(string)
}

variable "api_server_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
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

variable "cluster_name" {
  description = "The name of the AKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes minor version to use for the AKS cluster."
  type        = string
  default     = "1.21"

  validation {
    condition     = contains(["1.21"], var.cluster_version)
    error_message = "This module only supports AKS versions 1.21."
  }
}

variable "core_services_config" {
  description = "Configuration options for core platform services"
  type        = any
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin (kubenet or azure)"
  type        = string
  default     = "kubenet"
}

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name         = string
    single_vmss  = bool
    public       = bool
    node_type    = string
    node_size    = string
    min_capacity = number
    max_capacity = number
    labels       = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))
  default = null
}

variable "podnet_cidr" {
  description = "CIDR range for pod IP addresses when using the `kubenet` network plugin."
  type        = string
  default     = "100.65.0.0/16"
}

variable "resource_group_name" {
  description = "The name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to cloud resources."
  type        = map(string)
  default     = {}
}

variable "virtual_network" {
  description = "Virtual network configuration."
  type = object({
    subnets = object({
      private = object({
        id = string
      })
      public = object({
        id = string
      })
    })
    route_table_id = string
  })
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
  default     = "8.2.10"
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

variable "aks_workers_min" {
  description = "Min number of worker nodes"
  type        = number
  default     = 3
}

variable "aks_workers_max" {
  description = "Max number of worker nodes"
  type        = number
  default     = 3
}