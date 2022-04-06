resource "random_uuid" "volume_handle" {}

resource "kubernetes_persistent_volume" "blob_nfs" {
  depends_on = [
    helm_release.csi_driver,
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
      storage = each.value.size
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
      storage = var.spill_volume_size
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/host/mnt"
      }
    }
    storage_class_name = "spill"
  }
}