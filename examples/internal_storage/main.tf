data "azurerm_subscription" "current" {}

data "azuread_group" "subscription_owner" {
  display_name = "ris-azr-group-${data.azurerm_subscription.current.display_name}-owner"
}

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
  source = "git@github.com:Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v6.0.0"

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

#module "aks" {
#  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.10"
#
#  depends_on = [
#    module.virtual_network
#  ]
#
#  location            = module.metadata.location
#  resource_group_name = module.resource_group.name
#
#  cluster_name    = "${random_string.random.result}-aks-000"
#  cluster_version = "1.21"
#  network_plugin  = "kubenet"
#  sku_tier_paid   = true
#
#  cluster_endpoint_public_access = true
#  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]
#
#  virtual_network_resource_group_name = module.resource_group.name
#  virtual_network_name                = module.virtual_network.vnet.name
#  subnet_name                         = module.virtual_network.aks.demo.subnet.name
#  route_table_name                    = module.virtual_network.aks.demo.route_table.name
#
#  dns_resource_group_lookup = { "${var.dns_zone_name}" = var.dns_zone_resource_group }
#
#  admin_group_object_ids = [data.azuread_group.subscription_owner.object_id]
#
#  azuread_clusterrole_map = var.azuread_clusterrole_map
#
#  node_group_templates = [
#    {
#      name                = "workers"
#      node_os             = "ubuntu"
#      node_type           = "gpd"
#      node_type_version   = "v1"
#      node_size           = "large"
#      single_group        = true
#      min_capacity        = 1
#      max_capacity        = 25
#      placement_group_key = ""
#      taints              = []
#      labels = {
#        "lnrs.io/tier" = "standard"
#      }
#      tags = {}
#    }
#  ]
#
#  core_services_config = {
#    alertmanager = {
#      smtp_host = "appmail-test.risk.regn.net"
#      smtp_from = "foo@bar.com"
#      routes    = []
#      receivers = []
#    }
#
#    grafana = {
#      admin_password = "badPasswordDontUse"
#    }
#
#    ingress_internal_core = {
#      domain           = var.dns_zone_name
#      subdomain_suffix = random_string.random.result
#      public_dns       = true
#    }
#  }
#
#  tags = module.metadata.tags
#}