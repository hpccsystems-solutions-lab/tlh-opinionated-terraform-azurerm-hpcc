data "azurerm_subscription" "current" {}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

data "azuread_service_principal" "hpc_cache_resource_provider" {
  display_name = "HPC Cache Resource Provider"
}

# Random string for resource group 
resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "subscription" {
  source          = "git@github.com:Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = data.azurerm_subscription.current.subscription_id
}

module "naming" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-naming.git?ref=v1.0.81"
}

module "metadata" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.0"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "hpcc_demo"
  location            = "eastus2"
  environment         = "sandbox"
  product_name        = random_string.random.result
  business_unit       = "iog"
  product_group       = "hpcc"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v5.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.0.0.0/23"]

  aks_subnets = {
    demo = {
      private = {
        cidrs             = ["10.0.0.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }
      public = {
        cidrs             = ["10.0.1.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          local-vnet-address-space = {
            address_prefix = "10.0.0.0/23"
            next_hop_type  = "vnetlocal"
          }
        }
      }
    }
  }
}

module "aks" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.8"

  cluster_name    = random_string.random.result
  cluster_version = "1.21"
  sku_tier        = "Free"

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  ingress_node_pool = true

  node_pools = [
    {
      name                = "workers"
      single_vmss         = true
      public              = false
      node_type           = "x64-gpd-v1"
      node_size           = "2xlarge"
      min_capacity        = 1
      max_capacity        = 25
      taints              = []
      placement_group_key = ""
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]

  virtual_network                 = module.virtual_network.aks["demo"]
  core_services_config            = var.core_services_config
  azuread_clusterrole_map         = var.azuread_clusterrole_map
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${module.resource_group.name}"
}