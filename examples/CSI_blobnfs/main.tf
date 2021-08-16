data "azurerm_subscription" "current" {}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

# Random string for resource group 
resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = data.azurerm_subscription.current.subscription_id
}

module "naming" {
  source = "github.com/Azure-Terraform/example-naming-template.git?ref=v1.0.0"
}

module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.0"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "hpcc_demo"
  location            = "eastus2"
  environment         = "sandbox"
  product_name        = random_string.random.result
  business_unit       = "infra"
  product_group       = "hpcc"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v5.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = var.address_space

  aks_subnets = {
    demo = {
      private = {
        cidrs             = var.private_cidrs
        service_endpoints = ["Microsoft.Storage"]
      }
      public = {
        cidrs             = var.public_cidrs
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
            address_prefix = var.address_space[0]
            next_hop_type  = "vnetlocal"
          }
        }
      }
    }
  }
}

module "hpcc_cluster" {
  source = "../../"

  cluster_name        = random_string.random.result
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  virtual_network                 = module.virtual_network.aks["demo"]
  storage_network_subnet_ids      = [module.virtual_network.aks["demo"].subnets.private.id, module.virtual_network.aks["demo"].subnets.public.id]
  core_services_config            = var.core_services_config
  azuread_clusterrole_map         = var.azuread_clusterrole_map
  api_server_authorized_ip_ranges = merge(var.api_server_authorized_ip_ranges, { "my_ip" = chomp(data.http.my_ip.body) })

  // node_pool config

  // network config
  address_space = var.address_space

  hpcc_storage = var.hpcc_storage

}