module "csi_driver" {
  count = var.install_blob_csi_driver ? 1 : 0

  source = "./modules/csi_driver"
}

resource "random_uuid" "volume_handle" {}

resource "kubernetes_persistent_volume" "azurefiles" {
  depends_on = [
    azurerm_storage_share.azurefiles_admin_services
  ]

  for_each = local.azurefiles_services_storage

  metadata {
    annotations = {}
    labels = {
      storage-tier = "azurefiles"
    }
    name = "${var.namespace.name}-pv-azurefiles-${each.key}"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    capacity = {
      storage = each.value.size
    }

    mount_options = ["nconnect=8"]

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver        = "file.csi.azure.com"
        read_only     = false
        volume_handle = "${each.key}-${random_uuid.volume_handle.result}"
        volume_attributes = {
          protocol       = "smb"
          resourceGroup  = each.value.resource_group
          storageAccount = each.value.storage_account
          secretName     = kubernetes_secret.azurefiles_admin_services.0.metadata.0.name
          shareName      = azurerm_storage_share.azurefiles_admin_services[each.key].name
        }
      }
    }

    storage_class_name = "azurefile-csi-premium"
  }
}

resource "kubernetes_persistent_volume" "blob_nfs" {
  depends_on = [
    module.csi_driver,
    azurerm_storage_container.blob_nfs_admin_services,
    module.data_storage
  ]

  for_each = merge(local.blob_nfs_services_storage, local.blob_nfs_data_storage)

  metadata {
    annotations = {}
    labels = {
      storage-tier = "blobnfs"
    }
    name = "${var.namespace.name}-pv-blobnfs-${each.key}"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    capacity = {
      storage = each.value.size
    }

    mount_options = []

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver        = "blob.csi.azure.com"
        read_only     = false
        volume_handle = "${each.key}-${random_uuid.volume_handle.result}"
        volume_attributes = {
          resourceGroup  = each.value.resource_group
          storageAccount = each.value.storage_account
          containerName  = each.value.container_name
          protocol       = "nfs"
        }
      }
    }

    storage_class_name = "blobnfs"
  }
}

resource "kubernetes_persistent_volume" "hpc_cache" {

  depends_on = [
    module.data_cache
  ]

  for_each = local.hpc_cache_data_storage

  metadata {
    labels = {
      storage-tier = "hpccache"
    }
    name = "${var.namespace.name}-pv-hpc-cache-${each.key}"
  }
  spec {
    capacity = {
      storage = "${each.value.size}"
    }
    access_modes                     = ["ReadOnlyMany"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      nfs {
        server = each.value.server
        path   = each.value.path
      }
    }
    storage_class_name = "hpcc-data"
  }
}

resource "kubernetes_persistent_volume" "spill" {

  count = local.spill_space_enabled ? 1 : 0

  metadata {
    labels = {
      storage-tier = "spill"
    }
    name = "${var.namespace.name}-pv-spill"
  }
  spec {
    capacity = {
      storage = "${var.spill_volume_size}G"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/mnt"
      }
    }
    storage_class_name = "spill"
  }
}

resource "kubernetes_persistent_volume" "remotedata" {
  for_each = {
    for remote_storage in local.remote_storage_plane : "${remote_storage.subscription_name}.${remote_storage.storage_account_name}" => remote_storage
  }
  metadata {
    name = each.value.volume_name
    labels = {
      storage-tier = "blobnfs"
    }
  }
  spec {
    capacity = {
      storage = "1T"
    }
    access_modes                     = ["ReadOnlyMany"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      nfs {
        server = format("%s.blob.core.windows.net", each.value.storage_account_name)
        path   = each.value.storage_account_prefix
      }
    }
    storage_class_name = "blobnfs"
    mount_options      = ["nfsvers=3", "sec=sys", "nolock"]
  }
}