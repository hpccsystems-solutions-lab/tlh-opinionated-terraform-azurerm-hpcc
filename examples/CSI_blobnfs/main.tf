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
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.7"

  cluster_name    = random_string.random.result
  cluster_version = "1.21"

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  ingress_node_pool = true

  node_pools = [
    {
      name         = "workers"
      single_vmss  = false
      public       = false
      node_type    = "x64-gp-v1"
      node_size    = "medium"
      min_capacity = 3
      max_capacity = 6
      taints       = []
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


module "hpcc_cluster" {
  depends_on = [
    module.aks,
  ]

  source = "../../"

  aks_principal_id = module.aks.principal_id


  hpcc_helm_version = var.hpcc_helm_version
  jfrog_registry    = var.jfrog_registry

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  storage_account_authorized_ip_ranges = var.storage_account_authorized_ip_ranges
  storage_network_subnet_ids           = [module.virtual_network.aks["demo"].subnets.private.id, module.virtual_network.aks["demo"].subnets.public.id, var.tfe_prod_subnet_id]

  hpcc_storage_config               = var.hpcc_storage_config
  storage_account_delete_protection = false //defaults to true

}

## The DNS workaround should be enabled until the Helm chart supports the external-dns plugin 
/*
data "kubernetes_service" "eclwatch" {
  depends_on = [module.hpcc_cluster]
  metadata {
    name      = "eclwatch"
    namespace = "hpcc"
  }
}

resource "azurerm_dns_a_record" "eclwatch" {
  zone_name           = "us-infrastructure-dev.azure.lnrsg.io"
  resource_group_name = "app-dns-prod-eastus2"
  name                = "eclwatch-${random_string.random.result}"
  ttl                 = "30"
  records             = [data.kubernetes_service.eclwatch.status.0.load_balancer.0.ingress.0.ip]
}*/

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${module.resource_group.name}"
}
