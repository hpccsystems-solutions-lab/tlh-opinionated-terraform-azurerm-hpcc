module "aks" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.9"

  cluster_name    = "boolean-eastus-cluster"
  cluster_version = "1.21"

  location            = module.metadata_eastus.location
  tags                = module.metadata_eastus.tags
  resource_group_name = module.resource_group_eastus.name

  ingress_node_pool = true

  node_pools = [
    {
      name                = "workers"
      single_vmss         = false
      public              = false
      node_type           = "x64-memd-v1"
      node_size           = "2xlarge"
      min_capacity        = 3
      max_capacity        = 12
      taints              = []
      placement_group_key = ""
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]

  sku_tier = "Free"

  virtual_network                 = module.virtual_network_eastus.aks["roxie"]
  core_services_config            = local.core_services_config
  azuread_clusterrole_map         = var.azuread_clusterrole_map
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
}

