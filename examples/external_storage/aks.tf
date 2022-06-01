
module "aks" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.10"

  depends_on = [
    module.virtual_network
  ]

  location            = module.metadata.location
  resource_group_name = module.resource_group.name

  cluster_name    = "${random_string.random.result}-aks-000"
  cluster_version = "1.21"
  network_plugin  = "kubenet"
  sku_tier_paid   = true

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]

  virtual_network_resource_group_name = module.resource_group.name
  virtual_network_name                = module.virtual_network.vnet.name
  subnet_name                         = module.virtual_network.aks.demo.subnet.name
  route_table_name                    = module.virtual_network.aks.demo.route_table.name

  dns_resource_group_lookup = { "${var.dns_zone_name}" = var.dns_zone_resource_group }

  admin_group_object_ids = [data.azuread_group.subscription_owner.object_id]

  azuread_clusterrole_map = var.azuread_clusterrole_map

  node_group_templates = [
    {
      name                = "workers"
      node_os             = "ubuntu"
      node_type           = "gpd"
      node_type_version   = "v1"
      node_size           = "large"
      single_group        = true
      min_capacity        = 1
      max_capacity        = 25
      placement_group_key = ""
      taints              = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]

  core_services_config = {
    alertmanager = {
      smtp_host = "appmail-test.risk.regn.net"
      smtp_from = "foo@bar.com"
      routes    = []
      receivers = []
    }

    grafana = {
      admin_password = "badPasswordDontUse"
    }

    ingress_internal_core = {
      domain           = var.dns_zone_name
      subdomain_suffix = random_string.random.result
      public_dns       = true
    }
  }

  tags = module.metadata.tags
}
