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
  subnet_defaults = {
    enforce_private_link_endpoint_network_policies = true
    enforce_private_link_service_network_policies  = true
    cidrs                                          = []
    service_endpoints                              = []
    delegations                                    = {}
    create_network_security_group                  = true
    configure_nsg_rules                            = true
    allow_internet_outbound                        = false
    allow_lb_inbound                               = false
    allow_vnet_inbound                             = false
    allow_vnet_outbound                            = false
    route_table_association                        = null
  }

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


module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.3"

  cluster_name    = random_string.random.result
  cluster_version = "1.21"

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  network_plugin = "kubenet"

  node_pools = [
    {
      name         = "workers"
      single_vmss  = false
      public       = false
      node_type    = "x64-gp"
      node_size    = "large"
      min_capacity = 3
      max_capacity = 3
      taints       = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]

  virtual_network         = module.virtual_network.aks["demo"]
  core_services_config    = var.core_services_config
  azuread_clusterrole_map = var.azuread_clusterrole_map
  api_server_authorized_ip_ranges = merge(
    { "pod_cidr" = "100.65.0.0/16" },
    { for i, cidr in var.address_space : "subnet_cidr_${i}" => cidr },
    var.api_server_authorized_ip_ranges
  )
}

resource "azurerm_private_dns_zone" "azurecr" {
  name                = "azurecr.io"
  resource_group_name = module.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acrlink" {
  name                  = "acrlink"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.azurecr.name
  virtual_network_id    = module.virtual_network.aks["demo"].subnets.private.virtual_network_id
}

resource "azurerm_private_endpoint" "hpcc_acr" {
  name                = "hpcc-acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.virtual_network.aks["demo"].subnets.private.id
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.azurecr.id]
  }
  private_service_connection {
    name                           = "hpcc-acr-private-conn-1"
    private_connection_resource_id = "/subscriptions/0080ae59-04a9-4177-aa49-6c847f67e594/resourceGroups/app-prctroxieaks-dev-eastus2/providers/Microsoft.ContainerRegistry/registries/hpccacr"
    is_manual_connection           = true
    subresource_names              = ["registry"]
    request_message                = "ACR Private Link"
  }
}

module "hpcc_cluster" {
  depends_on = [
    module.aks,
    azurerm_private_endpoint.hpcc_acr
  ]
  #source = "github.com/LexisNexis-RBA/terraform-azurerm-hpcc.git?ref=v1.0.0-beta.1"
  source = "../../"

  aks_principal_id = module.aks.principal_id

  hpcc_image_root   = "hpccacr.azurecr.io"
  hpcc_image_name   = "hpccoperations/platform-core-ln"
  hpcc_helm_version = "8.4.0"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  storage_account_authorized_ip_ranges = var.storage_account_authorized_ip_ranges
  storage_network_subnet_ids           = [module.virtual_network.aks["demo"].subnets.private.id, module.virtual_network.aks["demo"].subnets.public.id]

  hpcc_storage_config               = var.hpcc_storage_config
  storage_account_delete_protection = false //defaults to true

}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${module.resource_group.name}"
}
