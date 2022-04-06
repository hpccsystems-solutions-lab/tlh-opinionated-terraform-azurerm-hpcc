output "data_planes" {
  value = [for plane_id in local.storage_plane_ids : {
    container_id         = azurerm_storage_container.hpcc_data[plane_id].resource_manager_id
    container_name       = azurerm_storage_container.hpcc_data[plane_id].name
    id                   = plane_id
    resource_group_name  = var.resource_group_name
    storage_account_id   = azurerm_storage_account.default[plane_id].id
    storage_account_name = azurerm_storage_account.default[plane_id].name
  }]
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "storage_accounts" {
  description = "Storage account objects."
  value = { for plane_id in local.storage_plane_ids : 
    plane_id => azurerm_storage_account.default[plane_id]
  }
}

output "storage_containers" {
  description = "Storage container objects."
  value = { for plane_id in local.storage_plane_ids : 
    plane_id => azurerm_storage_container.hpcc_data[plane_id]
  }
}