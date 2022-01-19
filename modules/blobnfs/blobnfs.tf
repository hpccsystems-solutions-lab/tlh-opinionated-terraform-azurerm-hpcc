resource "random_string" "random" {
  count   = var.hpcc_storage_account_name == "" ? 1 : 0
  length  = 5
  upper   = false
  number  = false
  special = false
}

resource "azurerm_storage_account" "storage_account" {
  count               = var.hpcc_storage_account_name == "" ? 1 : 0
  name                = "hpcc${random_string.random[0].result}"
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
  account_replication_type  = "LRS"


  network_rules {
    default_action             = "Deny"
    ip_rules                   = toset(values(var.storage_account_authorized_ip_ranges))
    virtual_network_subnet_ids = var.storage_network_subnet_ids
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "hpcc_storage_containers" {
  for_each              = var.hpcc_storage_account_name == "" ? var.hpcc_storage_config : {}
  name                  = "hpcc-${each.key}"
  storage_account_name  = azurerm_storage_account.storage_account[0].name
  container_access_type = "private"
}
/*
resource "azurerm_management_lock" "protect_storage_account" {
  count      = var.storage_account_delete_protection ? 1 : 0
  name       = "protect-storage"
  scope      = var.hpcc_storage_account_name == "" ? azurerm_storage_account.storage_account[0].id : data.azurerm_storage_account.storage_account[0].id
  lock_level = "CanNotDelete"
}
*/
