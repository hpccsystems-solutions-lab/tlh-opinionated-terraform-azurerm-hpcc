#############
# HPC Cache #
#############
resource "azurerm_hpc_cache" "hpc_cache" {

  name                = "hpc-cache-data"
  resource_group_name = var.resource_group_name
  location            = var.location
  cache_size_in_gb    = 6144
  subnet_id           = var.storage_network_subnet_ids[0]
  sku_name            = "Standard_2G"

  timeouts {
    create = "60m"
  }
}

resource "azurerm_hpc_cache_blob_nfs_target" "hpc_cache_blob" {
  depends_on = [
    azurerm_hpc_cache.hpc_cache,
  ]

  name                 = "hpc-cache-blob-data"
  resource_group_name  = var.resource_group_name
  cache_name           = azurerm_hpc_cache.hpc_cache.name
  storage_container_id = azurerm_storage_container.hpcc_storage_containers["data"].resource_manager_id
  namespace_path       = "/hpcc-data"
  usage_model          = "READ_HEAVY_INFREQ"
}

resource "azurerm_role_assignment" "cache_storage_account_contrib" {
  scope                = local.hpcc_storage_account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = var.object_id
}

resource "azurerm_role_assignment" "cache_blob_data_contrib" {
  scope                = local.hpcc_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.object_id
}

## HPC Cache DNS 
resource "azurerm_dns_a_record" "cache_dns_record" {

  name                = "hpc-cache-data"
  zone_name           = var.hpc_cache_dns_name.zone_name
  resource_group_name = var.hpc_cache_dns_name.zone_resource_group_name
  ttl                 = 300
  records             = azurerm_hpc_cache.hpc_cache.mount_addresses
}



## HPC Cache Persistent Volumes 

resource "kubernetes_persistent_volume" "hpccache" {
  metadata {
    name = "hpcc-data"
    labels = {
      storage-tier = "hpccache"
    }
  }
  spec {
    capacity = {
      storage = "6T"
    }
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      nfs {
        server = azurerm_dns_a_record.cache_dns_record.name
        path   = "/hpcc-data"
      }
    }
    storage_class_name = "hpcc-data"
  }
}
resource "kubernetes_persistent_volume_claim" "hpccache" {
  wait_until_bound = true
  metadata {
    name      = "hpcc-data"
    namespace = var.hpcc_namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "hpcc-data"
    resources {
      requests = {
        storage = "6T"
      }
    }
    selector {
      match_labels = {
        storage-tier = "hpccache"
      }
    }
    volume_name = kubernetes_persistent_volume.hpccache.metadata[0].name
  }

  timeouts {
    create = "20m"
  }
}