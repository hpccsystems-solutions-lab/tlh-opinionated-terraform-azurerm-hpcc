variable "cidr_block_aks_eastus" {
  type    = string
  default = ""
}
variable "cidr_block_aks_app_eastus" {
  type    = string
  default = ""
}
variable "cidr_block_aks_storage_eastus" {
  type    = string
  default = ""
}
variable "firewall_ip_eastus" {
  type    = string
  default = "10.241.2.68"
}
variable "expressroute_id_eastus" {
  type    = string
  default = "/subscriptions/977f34c1-5bba-493d-bba9-815edf8f5fc4/resourceGroups/shared-expressroute-prod-eastus-businesssvc-nonprod/providers/Microsoft.Network/virtualNetworks/networks-production-eastus-vnet"
}
variable "azure_admin_subnets" {
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
variable "cidr_block_aks_bool" {
  description = "CIDR for prod bool"
  type        = string
}
variable "boolroxie_prod_vnet_id" {
  description = "VNET ID for prod"
  type        = string
}
variable "esp_vnet_id" {
  type    = string
  default = "/subscriptions/e8bf8feb-5dc3-49a5-8eef-ddb971682c74/resourceGroups/app-esp-dev-eastus2/providers/Microsoft.Network/virtualNetworks/esp-nonprod-eastus2-vnet"
}
variable "cleaner_vnet_id" {
  type    = string
  default = "/subscriptions/38eab1d6-739c-46b5-ab44-7acb3bcca6ed/resourceGroups/app-addresscleaner-dev-eastus2/providers/Microsoft.Network/virtualNetworks/esp-nonprod-eastus2-vnet"
}

variable "hpcc_storage_config" {
  description = "Storage config for hpcc"
  type = map(object({
    container_name = string
    size           = string
    })
  )
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
  type        = object({
    password   = string
    username   = string
  })
  default = null
  sensitive = true
}

variable "hpc_cache" {
  description = "Creates the hpc-cache for the cluster."
  type = object({
    dns = object({
      zone_name                = string
      zone_resource_group_name = string
    })
    size = string
  })
  default = null
}

variable "ldap_user" {
  sensitive = true
}

variable "ldap_pass" {
  sensitive = true
}

variable "ldap_server" {
  type = string
}

variable "ldap_adminGroupName" {
  type = string
}

variable "ldap_filesBasedn" {
  type = string
}

variable "ldap_groupsBasedn" {
  type = string
}

variable "ldap_resourcesBasedn" {
  type = string
}

variable "ldap_sudoersBasedn" {
  type = string
}

variable "ldap_systemBasedn" {
  type = string
}

variable "ldap_usersBasedn" {
  type = string
}

variable "ldap_workunitsBasedn" {
  type = string
}

variable "hpcc_helm_chart_version" {
  description = "HPCC helm chart version"
  type        = string
}

variable "container_registry_auth" {
  description = "values to set as secrets for JFrog repo access"
  type = object({
    username = string
    password = string # API Token
  })
  sensitive = true
  default = null
}

variable "checkFileDate" {
  description = "Check file date to confirm integrity"
  type = bool
}

variable "logFullQueries" {
  description = "logs full query transaction"
  type = bool
}

variable "copyResources" {
  description = "After package map deployment copy or not files"
  type = bool
}

variable "parallelLoadQueries" {
  description = "Controls metadata querying from roxie to dali"
  type = number
}

variable "listenQueue" {
  description = "To be added"
  type = number
}

variable "numThreads" {
  description = "To be added"
  type = number
}

variable "visibility" {
  description = "To be added"
  type = string
}

variable "replicas" {
  description = "Number of data copies"
  type = number
}

variable "numChannels" {
  description = "Number of channels"
  type = number
}

variable "serverReplicas" {
  description = "Server replicas"
  type = number
}

variable "traceLevel" {
  description = "Application logging level from 1 to 10"
  type = number
}

variable "soapTraceLevel" {
  description = "Additional logging for SOAP transactions"
  type = number
}

variable "traceRemoteFiles" {
  description = "To be added"
  type = bool
}

variable "topoServer_replicas" {
  description = "To be added"
  type = bool
}

variable "channelResources_cpu" {
  description = "CPU limit for Roxie Pods"
  type = number
}

variable "channelResources_memory" {
  description = "Memory limit for Roxie Pods"
  type = string
}
