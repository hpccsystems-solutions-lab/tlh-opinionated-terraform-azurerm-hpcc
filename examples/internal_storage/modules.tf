
module "subscription" {
  source          = "git::ssh://git@github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = data.azurerm_subscription.current.subscription_id
}

module "naming" {
  source = "git::ssh://git@github.com/LexisNexis-RBA/terraform-azurerm-naming.git?ref=v1.0.81"
}

module "metadata" {
  source = "git::ssh://git@github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.0"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "hpcc-demo"
  location            = "eastus"
  environment         = "sandbox"
  product_name        = random_string.random.result
  business_unit       = "iog"
  product_group       = "hpcc"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "git::ssh://git@github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "git::ssh://git@github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v6.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.0.0.0/22"]

  subnets = {
    hpc_cache = { cidrs = ["10.0.1.0/26"]
      allow_vnet_inbound      = true
      allow_vnet_outbound     = true
      allow_internet_outbound = true
      service_endpoints       = ["Microsoft.Storage"]
    }
  }

  aks_subnets = {
    demo = {
      subnet_info = {
        cidrs             = ["10.0.0.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          local-vnet-10-1-0-0-22 = {
            address_prefix = "10.0.0.0/22"
            next_hop_type  = "VnetLocal"
          }
        }
      }
    }
  }
}
