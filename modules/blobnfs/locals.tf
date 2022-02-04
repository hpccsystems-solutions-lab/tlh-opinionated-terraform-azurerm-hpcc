locals {
  hpcc_storage_config = var.hpcc_storage_account_name != "" ? var.hpcc_storage_config : { for k, v in azurerm_storage_container.hpcc_storage_containers :
    k => {
      size           = var.hpcc_storage_config[k].size
      container_name = azurerm_storage_container.hpcc_storage_containers[k].name
    }
  }
  hpcc_storage_account_name        = var.hpcc_storage_account_name == "" ? azurerm_storage_account.storage_account[0].name : var.hpcc_storage_account_name
  hpcc_storage_account_id          = var.hpcc_storage_account_name == "" ? azurerm_storage_account.storage_account[0].id : data.azurerm_storage_account.storage_account[0].id
  hpcc_storage_resource_group_name = var.resource_group_name

  hpc_cache_name = var.hpc_cache_name == "" ? azurerm_dns_a_record.cache_dns_record.name : var.hpc_cache_name
}