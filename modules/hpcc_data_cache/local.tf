locals {
  hpc_cache_info = {
    small = {
      cache_size_in_gb = 21623
      sku              = "Standard_L4_5G"
    }
    medium = {
      cache_size_in_gb = 43246
      sku              = "Standard_L9G"
    }
    large = {
      cache_size_in_gb = 86491
      sku              = "Standard_L16G"
    }
  }

  usage_model = {
    never = "READ_HEAVY_INFREQ"
    "30s" = "WRITE_AROUND"
    "3h"  = "READ_HEAVY_CHECK_180"
  }

  hpc_cache_roles = [
    "Storage Account Contributor",
    "Storage Blob Data Contributor"
  ]

  storage_account_data_planes = flatten([for k, v in var.storage_targets : v.storage_account_data_planes])

  hpc_cache_role_assignments = merge(flatten(
    [for plane in local.storage_account_data_planes :
      { for role in local.hpc_cache_roles :
        "${plane.storage_account_name}-${role}" => {
          role_definition_name = role
          scope                = plane.storage_account_id
        }
      }
    ]
  )...)

  storage_planes = merge(flatten([for k, v in var.storage_targets :
    { for plane in v.storage_account_data_planes : "${k}-${plane.id}" => merge(
    { dataset = k, usage_model = local.usage_model[v.cache_update_frequency] }, plane) }
  ])...)
}