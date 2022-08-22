# VARIABLES 

variable "environment" {
  type = string
}

variable "azure_admin_subnets" {
  default = null
}

variable "aad_group_id" {
  default = null
  # description = "Group id of the Vault Service Principal."
  # This variable is populate by the Terraform Enterprise workspace"
  
}

variable "sku_tier" {
  type    = string
  default = "Free"
}
variable "firewall_ip" {
  type    = string
  default = "10.239.0.68"
}

variable "expressroute_id" {
  type    = string
  default = "/subscriptions/f77593b8-c144-4ed2-9038-fa8d1dabc54a/resourceGroups/app-expressroute-prod-useast2/providers/Microsoft.Network/virtualNetworks/app-expressroute-prod-useast2-vnet"
}

variable "boolroxie_prod_vnet_id" {
  description = "VNET ID for prod"
  default     = "/subscriptions/02a6ed56-3583-4d5e-a4f5-120c5597ad0b/resourceGroups/app-boolroxie-dev-eastus2/providers/Microsoft.Network/virtualNetworks/hpccops-dev-eastus2-vnet"
  type        = string
}

variable "cidr_block_prctroxieaks" {
  type = string
}

variable "cidr_block_prctroxieacr" {
  type = string
}

variable "cidr_block_prctroxieaks_roxie" {
  type = string
}

variable "cidr_block_prctroxieaks_storage" {
  type = string
}

variable "create_network_security_group" {
  description = "Create/associate network security group"
  type        = bool
  default     = true
}

variable "configure_nsg_rules" {
  description = "Configure network security group rules"
  type        = bool
  default     = true # false
}

variable "allow_internet_outbound" {
  description = "allow outbound traffic to internet"
  type        = bool
  default     = true
}

variable "allow_lb_inbound" {
  description = "allow inbound traffic from Azure Load Balancer"
  type        = bool
  default     = true
}

variable "allow_vnet_inbound" {
  description = "allow all inbound from virtual network"
  type        = bool
  default     = true
}

variable "allow_vnet_outbound" {
  description = "allow all outbound from virtual network"
  type        = bool
  default     = true
}

variable "enforce_private_link_endpoint_network_policies" {
  description = "Enforce private link endpoint network policies?"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

variable "storage_account_authorized_ip_ranges" {
  description = "Map of authorized CIDRs / IPs"
  type        = map(string)
}

# HPCC
variable "hpcc_storage_config" {
  description = "Storage config for hpcc"
  type = map(object({
    container_name = string
    size           = string
    })
  )
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
  sensitive = true
  # default   = null
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

variable "private_cidrs" {
  description = "Private AKS cidrs"
  type        = list(string)
}

variable "public_cidrs" {
  description = "Public AKS cidrs"
  type        = list(string)
}

variable "tfe_prod_subnet_id" {
  description = "Terraform enterprise Subnet id"
  type        = string
  default     = "/subscriptions/debc4966-2669-4fa7-9bd9-c4cdb08aed9f/resourceGroups/app-tfe-prod-useast2/providers/Microsoft.Network/virtualNetworks/core-production-useast2-vnet/subnets/iaas-public"

}

# JFrog
variable "jfrog_registry" {
  description = "values to set as secrets for JFrog repo access"
  type = object({
    image_root = string
    image_name = string
    version    = string
  })
  sensitive = true
}

variable "container_registry_auth" {
  description = "values to set as secrets for JFrog repo access"
  type = object({
    username = string
    password = string # API Token
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
    cluster_admin_users = {
    }
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}