output "data_planes" {
  description = "Data plane object for use with HPCC terraform module."
  value = { for dataset, config in var.storage_targets :
    dataset => [for plane in config.storage_account_data_planes :
      {
        id     = plane.id
        server = azurerm_dns_a_record.default.fqdn
        path   = azurerm_hpc_cache_blob_nfs_target.default["${dataset}-${plane.id}"].namespace_path
      }
    ]
  }
}

output "fqdn" {
  description = "Azure DNS fqdn for HPC Cache."
  value       = azurerm_dns_a_record.default.fqdn
}

output "hpc_cache" {
  description = "HPC Cache object."
  value       = azurerm_hpc_cache.default
}

output "hpc_cache_id" {
  description = "HPC Cache id."
  value       = azurerm_hpc_cache.default.id
}

output "hpc_cache_name" {
  description = "HPC Cache name."
  value       = azurerm_hpc_cache.default.name
}

output "resource_group_name" {
  description = "Resource group name containing the HPC Cache."
  value       = var.resource_group_name
}