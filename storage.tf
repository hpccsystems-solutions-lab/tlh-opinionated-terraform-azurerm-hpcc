resource "random_string" "random" {
  length  = 5
  upper   = false
  numeric = false
  special = false
}

resource "azurerm_storage_account" "azurefiles_admin_services" {
  count = local.azurefiles_admin_storage_enabled ? 1 : 0

  name                = "hpcc${random_string.random.result}afsvc"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  access_tier                     = "Hot"
  account_kind                    = "FileStorage"
  account_tier                    = "Premium"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  shared_access_key_enabled = true

  enable_https_traffic_only = false
  account_replication_type  = var.admin_services_storage_account_settings.replication_type

  network_rules {
    default_action             = "Deny"
    ip_rules                   = values(var.admin_services_storage_account_settings.authorized_ip_ranges)
    virtual_network_subnet_ids = values(var.admin_services_storage_account_settings.subnet_ids)
    bypass                     = ["AzureServices"]
  }
  share_properties {
    retention_policy {
      days = var.admin_services_storage_account_settings.file_share_retention_days
    }
  }
}

resource "azurerm_storage_account" "blob_nfs_admin_services" {
  count = local.blobnfs_admin_storage_enabled ? 1 : 0

  name                = "hpcc${random_string.random.result}blobsvc"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  access_tier                     = "Hot"
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"

  shared_access_key_enabled = true

  nfsv3_enabled             = true
  enable_https_traffic_only = true
  account_replication_type  = var.admin_services_storage_account_settings.replication_type


  network_rules {
    default_action             = "Deny"
    ip_rules                   = values(var.admin_services_storage_account_settings.authorized_ip_ranges)
    virtual_network_subnet_ids = values(var.admin_services_storage_account_settings.subnet_ids)
    bypass                     = ["AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = var.admin_services_storage_account_settings.blob_soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = var.admin_services_storage_account_settings.container_soft_delete_retention_days
    }
  }
}

resource "kubernetes_secret" "azurefiles_admin_services" {
  count = contains([for storage in var.admin_services_storage : storage.type], "azurefiles") ? 1 : 0

  depends_on = [
    azurerm_storage_account.azurefiles_admin_services
  ]

  metadata {
    name = "${var.namespace.name}-azurefiles-admin-services"
    labels = {
      name = "azurefiles-admin-services"
    }
  }

  data = {
    azurestorageaccountname = azurerm_storage_account.azurefiles_admin_services.0.name
    azurestorageaccountkey  = azurerm_storage_account.azurefiles_admin_services.0.primary_access_key
  }

  type = "kubernetes.io/generic"
}

resource "azurerm_storage_share" "azurefiles_admin_services" {
  for_each = local.azurefiles_services_storage

  name                 = each.value.container_name
  storage_account_name = azurerm_storage_account.azurefiles_admin_services.0.name
  quota                = trimsuffix(each.value.size, "G")
  enabled_protocol     = var.environment == "dev" ? "NFS" : "SMB"
}

resource "azurerm_storage_container" "blob_nfs_admin_services" {
  for_each = local.blob_nfs_services_storage

  name                  = each.value.container_name
  storage_account_name  = azurerm_storage_account.blob_nfs_admin_services.0.name
  container_access_type = "private"
}

resource "azurerm_management_lock" "protect_admin_storage_account" {
  depends_on = [
    azurerm_storage_account.azurefiles_admin_services,
    azurerm_storage_account.blob_nfs_admin_services
  ]

  for_each = var.admin_services_storage_account_settings.delete_protection ? merge(
    local.azurefiles_admin_storage_enabled ? { "${azurerm_storage_account.azurefiles_admin_services.0.name}" = azurerm_storage_account.azurefiles_admin_services.0.id } : {},
    local.blobnfs_admin_storage_enabled ? { "${azurerm_storage_account.blob_nfs_admin_services.0.name}" = azurerm_storage_account.blob_nfs_admin_services.0.id } : {}
  ) : {}

  name       = "protect-storage-${each.key}"
  scope      = each.value
  lock_level = "CanNotDelete"
}

module "data_storage" {
  depends_on = [
    random_string.random
  ]

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

  storage_targets = {
    internal = {
      cache_update_frequency = var.data_storage_config.internal.hpc_cache.cache_update_frequency
      storage_account_data_planes = (var.data_storage_config.internal.hpc_cache.storage_account_data_planes == null ?
      module.data_storage.0.data_planes : var.data_storage_config.internal.hpc_cache.storage_account_data_planes)
    }
  }
}
