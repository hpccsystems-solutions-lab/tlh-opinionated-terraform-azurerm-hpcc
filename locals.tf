locals {
  api_server_authorized_ip_ranges_local = merge({
    "podnet_cidr" = var.podnet_cidr
    },
    { for i, cidr in var.address_space : "subnet_cidr_${i}" => cidr },
    var.api_server_authorized_ip_ranges
  )


  hpcc_config = {
    path_prefix = "/var/lib/HPCCSystems"
    storage = {
      data = {
        path     = "hpcc-data"
        pvc_name = kubernetes_persistent_volume_claim.hpcc_blob_pvcs["data"].metadata.0.name
      }
      dali = {
        path     = "dalistorage"
        pvc_name = kubernetes_persistent_volume_claim.hpcc_blob_pvcs["dali"].metadata.0.name
      }
      sasha = {
        path     = "sashastorage"
        pvc_name = kubernetes_persistent_volume_claim.hpcc_blob_pvcs["sasha"].metadata.0.name
      }
      dll = {
        path     = "queries"
        pvc_name = kubernetes_persistent_volume_claim.hpcc_blob_pvcs["dll"].metadata.0.name
      }
      mydropzone = {
        path     = "mydropzone"
        pvc_name = kubernetes_persistent_volume_claim.hpcc_blob_pvcs["mydropzone"].metadata.0.name
        category = "lz"
      }
    }
  }

  
  hpcc_namespaces = [
    var.hpcc_namespace,
    "blob-csi-driver"
  ]

}