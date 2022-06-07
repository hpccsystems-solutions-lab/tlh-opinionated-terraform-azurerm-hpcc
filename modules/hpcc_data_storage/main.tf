resource "azurerm_storage_account" "default" {
  for_each = local.storage_plane_ids

  name                = "${var.storage_account_name_prefix}${each.value}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  access_tier                     = "Hot"
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"

  shared_access_key_enabled = false

  nfsv3_enabled             = true
  enable_https_traffic_only = true
  account_replication_type  = var.storage_account_settings.replication_type

  network_rules {
    default_action             = "Deny"
    ip_rules                   = values(var.storage_account_settings.authorized_ip_ranges)
    virtual_network_subnet_ids = values(var.storage_account_settings.subnet_ids)
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "hpcc_data" {
  for_each = local.storage_plane_ids

  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.default[each.value].name
  container_access_type = "private"
}

resource "azurerm_management_lock" "protect_storage_account" {
  for_each = var.storage_account_settings.delete_protection ? local.storage_plane_ids : []

  name       = "protect-storage-${azurerm_storage_account.default[each.value].name}"
  scope      = azurerm_storage_account.default[each.value].id
  lock_level = "CanNotDelete"
}
