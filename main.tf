
resource "kubernetes_namespace" "hpcc_namespaces" {

  for_each = toset(local.hpcc_namespaces)

  metadata {
    name = each.key

    labels = {
      name = each.key
    }
  }
}

resource "kubernetes_namespace" "csi_driver_namespaces" {

  count = var.blob-csi-driver ? 1 : 0 

  metadata {
    name = "blob-csi-driver"

    labels = {
      name = "blob-csi-driver"
    }
  }
}

module "hpcc_storage" {

  source = "./modules/blobnfs"

  location            = var.location
  tags                = var.tags
  resource_group_name = var.hpcc_storage_account_name == "" ? var.resource_group_name : var.hpcc_storage_account_resource_group_name

  storage_network_subnet_ids           = var.storage_network_subnet_ids
  storage_account_authorized_ip_ranges = var.storage_account_authorized_ip_ranges
  storage_account_delete_protection    = var.storage_account_delete_protection

  hpcc_storage_account_name = var.hpcc_storage_account_name
  hpcc_storage_config       = var.hpcc_storage_config
  hpc_cache_dns_name        = var.hpc_cache_dns_name
}


resource "azurerm_role_assignment" "hpcc_storage_account_contrib" {
  scope                = module.hpcc_storage.account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = var.aks_principal_id
}

resource "azurerm_role_assignment" "hpcc_blob_data_contrib" {
  scope                = module.hpcc_storage.account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.aks_principal_id
}

resource "helm_release" "csi_driver" {
  depends_on = [
    module.hpcc_storage
  ]
  count = var.blob-csi-driver ? 1 : 0
  chart      = "blob-csi-driver"
  name       = "blob-csi-driver"
  namespace  = "blob-csi-driver"
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version    = "v1.3.0"
}

resource "random_uuid" "volume_handle" {}

resource "kubernetes_persistent_volume" "hpcc_blob_volumes" {
  depends_on = [
    helm_release.csi_driver
  ]

  for_each = module.hpcc_storage.config
  metadata {
    name = "pv-blob-${var.hpcc_namespace}-${each.key}"
    labels = {
      storage-tier = "blobnfs"
    }
  }

  spec {
    capacity = {
      storage = each.value.size
    }
    access_modes = ["ReadWriteMany"]

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver        = "blob.csi.azure.com"
        read_only     = false
        volume_handle = "${each.key}-${random_uuid.volume_handle.result}"
        volume_attributes = {
          resourceGroup  = module.hpcc_storage.resource_group_name
          storageAccount = module.hpcc_storage.account_name
          containerName  = each.value.container_name
          protocol       = "nfs"
        }
      }
    }

    storage_class_name = "blobnfs"
  }
}

resource "kubernetes_persistent_volume_claim" "hpcc_blob_pvcs" {
  for_each = module.hpcc_storage.config
  metadata {
    name      = "pvc-blob-${each.key}-nfs"
    namespace = var.hpcc_namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "blobnfs"
    resources {
      requests = {
        storage = each.value.size
      }
    }
    selector {
      match_labels = {
        storage-tier = "blobnfs"
      }
    }
    volume_name = kubernetes_persistent_volume.hpcc_blob_volumes[each.key].metadata.0.name
  }
}

resource "helm_release" "hpcc" {
  depends_on = [
    kubernetes_persistent_volume_claim.hpcc_blob_pvcs,
  ]
  name       = var.hpcc_namespace
  namespace  = var.hpcc_namespace
  chart      = "hpcc"
  repository = "https://hpcc-systems.github.io/helm-chart"
  version    = var.hpcc_helm_version
  values = [
    yamlencode(local.chart_values)
  ]
}

## The DNS workaround should be enabled until the Helm chart supports the external-dns plugin 
/*
data "kubernetes_service" "eclwatch" {
  depends_on = [module.hpcc_cluster]
  metadata {
    name      = "eclwatch"
    namespace = "hpcc"
  }
}

resource "azurerm_dns_a_record" "eclwatch" {
  zone_name           = "us-infrastructure-dev.azure.lnrsg.io"
  resource_group_name = "app-dns-prod-eastus2"
  name                = "eclwatch-${random_string.random.result}"
  ttl                 = "30"
  records             = [data.kubernetes_service.eclwatch.status.0.load_balancer.0.ingress.0.ip]
}

output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${module.resource_group.name}"
}*/