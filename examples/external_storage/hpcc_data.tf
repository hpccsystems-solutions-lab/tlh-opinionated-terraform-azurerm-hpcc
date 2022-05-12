module "hpcc_data_storage" {
  depends_on = [
    module.virtual_network
  ]

  source = "../../modules/hpcc_data_storage"

  storage_account_name_prefix = "hpcc${random_string.random.result}data"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  data_plane_count = 5
  storage_account_settings = {
    replication_type     = "LRS"
    authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
    delete_protection    = false
    subnet_ids = {
      aks = module.virtual_network.aks.demo.subnet.id
    }
  }
}


module "hpcc_data_cache" {
  depends_on = [
    module.virtual_network,
    module.hpcc_data_storage
  ]

  source = "../../modules/hpcc_data_cache"

  name                = "hpcc${random_string.random.result}"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  dns = {
    zone_name                = var.dns_zone_name
    zone_resource_group_name = var.dns_zone_resource_group
  }

  resource_provider_object_id = data.azuread_service_principal.hpc_cache_resource_provider.object_id
  size                        = "small"

  storage_targets = {
    external = {
      cache_update_frequency      = "3h"
      storage_account_data_planes = module.hpcc_data_storage.data_planes
    }
  }

  subnet_id = module.virtual_network.aks.demo.subnet.id
  tags      = module.metadata.tags
}