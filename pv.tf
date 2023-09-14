module "csi_driver" {
  count = var.install_blob_csi_driver ? 1 : 0

  source = "./modules/csi_driver"
}

resource "random_uuid" "volume_handle" {}


resource "kubernetes_persistent_volume" "azurefiles" {
  depends_on = [
    azurerm_storage_share.azurefiles_admin_services,
    kubernetes_storage_class.premium_zrs_file_share_storage_class
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

    mount_options = each.value.protocol == "nfs" ? ["nconnect=8"] : ["file_mode=0644", "dir_mode=0755", "mfsymlinks", "uid=10000", "gid=10001", "actimeo=30", "cache=strict"]

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver        = "file.csi.azure.com"
        read_only     = false
        volume_handle = "${each.key}-${random_uuid.volume_handle.result}"
        volume_attributes = {
          protocol       = each.value.protocol
          resourceGroup  = each.value.resource_group
          storageAccount = each.value.storage_account
          secretName     = kubernetes_secret.azurefiles_admin_services.0.metadata.0.name
          shareName      = azurerm_storage_share.azurefiles_admin_services[each.key].name
        }
      }
    }

    storage_class_name = each.value.protocol == "nfs" ? "azurefile-csi-premium" : "hpcc-premium-zrs-file-share-sc"
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

# Multiple Spill PVs - Issue #123

resource "kubernetes_persistent_volume" "spill" {

  for_each = local.spill_space_enabled ? var.spill_volumes : {}
  metadata {
    labels = {
      storage-tier = each.value.storage_class
    }
    name = "${var.namespace.name}-pv-${each.value.name}"
  }
  spec {
    capacity = {
      storage = "${each.value.size}G"
    }
    access_modes = ["${each.value.access_mode}"]
    persistent_volume_source {
      host_path {
        path = each.value.host_path
      }
    }
    storage_class_name = each.value.storage_class
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
