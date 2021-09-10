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

resource "azurerm_storage_account" "storage_account" {

  name                = "hpccstorage"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  allow_blob_public_access = false
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"


  nfsv3_enabled             = true
  enable_https_traffic_only = true
  account_replication_type  = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = concat(values(var.api_server_authorized_ip_ranges), ["${chomp(data.http.my_ip.body)}"])
    virtual_network_subnet_ids = [module.virtual_network.aks["demo"].subnets.private.id, module.virtual_network.aks["demo"].subnets.public.id]
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "hpcc_storage_containers" {
  for_each              = var.hpcc_storage_sizes
  name                  = "hpcc-${each.key}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}


locals {
  hpcc_storage_config = {for k,v in azurerm_storage_container.hpcc_storage_containers : 
    k => {
      size = var.hpcc_storage_sizes[k]
      container_name = azurerm_storage_container.hpcc_storage_containers[k].name
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
  api_server_authorized_ip_ranges = merge(var.api_server_authorized_ip_ranges, { "my_ip" = "${chomp(data.http.my_ip.body)}/32" })
  storage_account_authorized_ip_ranges = var.storage_account_authorized_ip_ranges
  // node_pool config

  // network config
  address_space = var.address_space

  hpcc_storage_account_name           = "hpccstorage"
  hpcc_storage_account_resource_group_name  = module.resource_group.name
  hpcc_storage_config               = local.hpcc_storage_config
  storage_account_delete_protection = false //defaults to true

}

output "aks_login" {
  value = module.hpcc_cluster.aks_login
}
