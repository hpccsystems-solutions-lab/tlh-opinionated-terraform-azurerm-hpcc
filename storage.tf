resource "random_string" "random" {
  length  = 5
  upper   = false
  number  = false
  special = false
}

resource "azurerm_storage_account" "services" {
  name                = "hpcc${random_string.random.result}services"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  allow_blob_public_access = false
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  shared_access_key_enabled = false

  nfsv3_enabled             = true
  enable_https_traffic_only = true
  account_replication_type  = var.services_storage_account_settings.replication_type


  network_rules {
    default_action             = "Deny"
    ip_rules                   = values(var.services_storage_account_settings.authorized_ip_ranges)
    virtual_network_subnet_ids = values(var.services_storage_account_settings.subnet_ids)
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "services" {
  for_each = local.blob_nfs_services_storage

  name                  = each.value.container_name
  storage_account_name  = azurerm_storage_account.services.name
  container_access_type = "private"
}

resource "azurerm_management_lock" "protect_storage_account" {
  count = var.services_storage_account_settings.delete_protection ? 1 : 0

  name       = "protect-storage-${azurerm_storage_account.services.name}"
  scope      = azurerm_storage_account.services.id
  lock_level = "CanNotDelete"
}

module "data_storage" {
  source = "./modules/hpcc_data_storage"

  count = local.create_data_storage ? 1 : 0

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags


  data_plane_count            = var.data_storage_config.internal.blob_nfs.data_plane_count
  storage_account_name_prefix = "hpcc${random_string.random.result}data"
  storage_account_settings    = var.data_storage_config.internal.blob_nfs.storage_account_settings
}

module "data_cache" {
  depends_on = [
    module.data_storage
  ]
  source = "./modules/hpcc_data_cache"

  count = local.create_data_cache ? 1 : 0

  name                = "hpcc${random_string.random.result}cache"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  resource_provider_object_id = var.data_storage_config.internal.hpc_cache.resource_provider_object_id

  dns       = var.data_storage_config.internal.hpc_cache.dns
  size      = var.data_storage_config.internal.hpc_cache.size
  subnet_id = var.data_storage_config.internal.hpc_cache.subnet_id

  storage_targets = { for k,v in var.data_storage_config.internal.hpc_cache.storage_targets :
    k => {
      cache_update_frequency = v.cache_update_frequency
      storage_account_data_planes = (v.storage_account_data_planes == null ? 
        module.data_storage.0.data_planes : v.storage_account_data_planes)
    }
  }
}