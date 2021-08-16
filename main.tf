module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git?ref=v0.12.0"

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
      min_capacity = 3
      max_capacity = 3
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
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
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
resource "azurerm_storage_account" "storage_account" {
  depends_on = [
    module.aks
  ]

  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  allow_blob_public_access = false
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"


  nfsv3_enabled             = true
  enable_https_traffic_only = true
  account_replication_type  = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = values(var.api_server_authorized_ip_ranges)
    virtual_network_subnet_ids = var.storage_network_subnet_ids
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_management_lock" "protect_storage_account" {
  count = var.storage_account_delete_protection ? 1 : 0
  name = "protect-storage"
  scope = azurerm_storage_account.storage_account.id
  lock_level = "CanNotDelete"
}

resource "azurerm_storage_container" "hpcc_storage_containers" {
  for_each              = var.hpcc_storage
  name                  = "hpcc-${each.key}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "helm_release" "csi_driver" {
  depends_on = [
    module.aks,
    azurerm_storage_container.hpcc_storage_containers
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

  for_each = var.hpcc_storage
  metadata {
    name = "pv-blob-${each.key}"
    labels = {
      storage-tier = "blobnfs"
    }
  }

  spec {
    capacity = {
      storage = each.value
    }
    access_modes = ["ReadWriteMany"]

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver        = "blob.csi.azure.com"
        read_only     = false
        volume_handle = "${each.key}-${random_uuid.volume_handle.result}"
        volume_attributes = {
          resourceGroup  = var.resource_group_name
          storageAccount = azurerm_storage_account.storage_account.name
          containerName  = azurerm_storage_container.hpcc_storage_containers[each.key].name
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
  for_each = var.hpcc_storage
  metadata {
    name      = "pvc-blob-${each.key}-nfs"
    namespace = var.hpcc_namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "blobnfs"
    resources {
      requests = {
        storage = each.value
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
  values     = [templatefile("${path.module}/hpcc_system_values.yaml.tpl", local.hpcc_config)]
}
