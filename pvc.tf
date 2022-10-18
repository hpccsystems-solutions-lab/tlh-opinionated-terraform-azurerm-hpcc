resource "kubernetes_persistent_volume_claim" "azurefiles" {
  depends_on = [
    kubernetes_namespace.default,
    kubernetes_persistent_volume.azurefiles
  ]

  for_each = local.azurefiles_services_storage

  metadata {
    name      = "pvc-azurefiles-${each.key}"
    namespace = var.namespace.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    selector {
      match_labels = {
        storage-tier = "azurefiles"
      }
    }
    storage_class_name = each.value.protocol == "nfs" ? "azurefile-csi-premium" : "hpcc-premium-zrs-file-share-sc"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.azurefiles[each.key].spec.0.capacity.storage
      }
    }
    volume_name = kubernetes_persistent_volume.azurefiles[each.key].metadata.0.name
  }
}

resource "kubernetes_persistent_volume_claim" "blob_nfs" {
  depends_on = [
    kubernetes_namespace.default,
    kubernetes_persistent_volume.blob_nfs
  ]

  for_each = merge(local.blob_nfs_services_storage, local.blob_nfs_data_storage)

  metadata {
    name      = "pvc-blob-${each.key}"
    namespace = var.namespace.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    selector {
      match_labels = {
        storage-tier = "blobnfs"
      }
    }
    storage_class_name = "blobnfs"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.blob_nfs[each.key].spec.0.capacity.storage
      }
    }
    volume_name = kubernetes_persistent_volume.blob_nfs[each.key].metadata.0.name
  }
}

resource "kubernetes_persistent_volume_claim" "hpc_cache" {
  depends_on = [
    kubernetes_namespace.default,
    kubernetes_persistent_volume.hpc_cache
  ]

  for_each = local.hpc_cache_data_storage

  wait_until_bound = true
  metadata {
    name      = "pvc-hpc-cache-${each.key}"
    namespace = var.namespace.name
  }
  spec {
    access_modes       = ["ReadOnlyMany"]
    storage_class_name = "hpcc-data"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.hpc_cache[each.key].spec.0.capacity.storage
      }
    }
    selector {
      match_labels = {
        storage-tier = "hpccache"
      }
    }
    volume_name = kubernetes_persistent_volume.hpc_cache[each.key].metadata.0.name
  }

  timeouts {
    create = "20m"
  }
}

resource "kubernetes_persistent_volume_claim" "spill" {
  depends_on = [
    kubernetes_namespace.default,
    kubernetes_persistent_volume.spill
  ]

  count = local.spill_space_enabled ? 1 : 0

  metadata {
    name      = "pvc-spill"
    namespace = var.namespace.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.spill_volume_size}G"
      }
    }
    selector {
      match_labels = {
        storage-tier = "spill"
      }
    }
    storage_class_name = "spill"
    volume_name        = kubernetes_persistent_volume.spill.0.metadata.0.name
  }
}

resource "kubernetes_persistent_volume_claim" "remotedata" {
  wait_until_bound = true
  for_each = {
    for remote_storage in local.remote_storage_plane : "${remote_storage.subscription_name}.${remote_storage.storage_account_name}" => remote_storage
  }
  metadata {
    name      = each.value.volume_claim_name
    namespace = "hpcc"
  }
  spec {
    access_modes       = ["ReadOnlyMany"]
    storage_class_name = "blobnfs"
    resources {
      requests = {
        storage = "1T"
      }
    }
    selector {
      match_labels = {
        storage-tier = "blobnfs"
      }
    }
    volume_name = each.value.volume_name
  }

  timeouts {
    create = "5m"
  }
}