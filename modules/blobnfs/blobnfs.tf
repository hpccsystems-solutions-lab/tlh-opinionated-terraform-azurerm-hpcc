resource "random_string" "random" {
  count   = var.hpcc_storage_account_name == "" ? 1 : 0
  length  = 5
  upper   = false
  number  = false
  special = false
}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

module "storage_account" {
  source = "github.com/Azure-Terraform/terraform-azurerm-storage-account.git?ref=v0.12.1"
  count  = var.hpcc_storage_account_name == "" ? 1 : 0

  name                = "hpcc${random_string.random[0].result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  allow_blob_public_access = false
  enable_hns               = true
  min_tls_version          = "TLS1_2"

  shared_access_key_enabled = false

  nfsv3_enabled             = true
  enable_https_traffic_only = true
  replication_type          = "LRS"

  access_list = {
    "my_ip" = data.http.my_ip.body
  }

  service_endpoints = var.service_endpoints
}

resource "azurerm_storage_container" "hpcc_storage_containers" {
  for_each              = var.hpcc_storage_account_name == "" ? var.hpcc_storage_config : {}
  name                  = "hpcc-${each.key}"
  storage_account_name  = module.storage_account[0].name
  container_access_type = "private"
}

/*
// Removing this resource block as the lock was creating an issue during terraform re-deployment

resource "azurerm_management_lock" "protect_storage_account" {
  count      = var.storage_account_delete_protection ? 1 : 0
  name       = "protect-storage"
  scope      = var.hpcc_storage_account_name == "" ? azurerm_storage_account.storage_account[0].id : data.azurerm_storage_account.storage_account[0].id
  lock_level = "CanNotDelete"
}
*/
