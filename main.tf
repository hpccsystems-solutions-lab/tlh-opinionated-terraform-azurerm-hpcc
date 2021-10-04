

module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.3"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name

  network_plugin = var.network_plugin

  node_pools = [
    {
      name         = "ingress"
      single_vmss  = true
      public       = false
      node_type    = "x64-gp"
      node_size    = "medium"
      min_capacity = 1
      max_capacity = 3
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      tags = {}
    },
    {
      name         = "workers"
      single_vmss  = false
      public       = false
      node_type    = "x64-gp"
      node_size    = "large"
      min_capacity = var.aks_workers_min
      max_capacity = var.aks_workers_max
      taints       = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]

  virtual_network                 = var.virtual_network
  core_services_config            = var.core_services_config
  azuread_clusterrole_map         = var.azuread_clusterrole_map
  api_server_authorized_ip_ranges = local.api_server_authorized_ip_ranges_local
}

resource "kubernetes_namespace" "hpcc_namespaces" {
  depends_on = [
    module.aks
  ]

  for_each = toset(local.hpcc_namespaces)

  metadata {
    name = each.key

    labels = {
      name = each.key
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

module "hpcc_storage" {
  depends_on          = [module.aks]
  source              = "./modules/blobnfs"
  cluster_name        = var.cluster_name
  location            = var.location
  tags                = var.tags
  resource_group_name = var.hpcc_storage_account_name == "" ? var.resource_group_name : var.hpcc_storage_account_resource_group_name

  storage_network_subnet_ids           = var.storage_network_subnet_ids
  storage_account_authorized_ip_ranges = var.storage_account_authorized_ip_ranges

  hpcc_storage_account_name = var.hpcc_storage_account_name
  hpcc_storage_config       = var.hpcc_storage_config
}


resource "azurerm_role_assignment" "hpcc_storage_account_contrib" {
  scope = module.hpcc_storage.account_id
  role_definition_name = "Storage Account Contributor"
  principal_id = module.aks.principal_id
}

resource "azurerm_role_assignment" "hpcc_blob_data_contrib" {
  scope = module.hpcc_storage.account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = module.aks.principal_id
}

resource "helm_release" "csi_driver" {
  depends_on = [
    module.aks,
    module.hpcc_storage
  ]
  chart      = "blob-csi-driver"
  name       = "blob-csi-driver"
  namespace  = "blob-csi-driver"
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version    = "v1.3.0"
}

resource "random_uuid" "volume_handle" {}

resource "kubernetes_persistent_volume" "hpcc_blob_volumes" {
  depends_on = [
    module.aks,
    helm_release.csi_driver
  ]

  for_each = module.hpcc_storage.config
  metadata {
    name = "pv-blob-${each.key}"
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
  depends_on = [
    module.aks
  ]
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
    module.aks
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
