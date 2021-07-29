# Random string for resource group 

resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = data.azurerm_subscription.current.subscription_id
}

module "naming" {
  source = "github.com/Azure-Terraform/example-naming-template.git?ref=v1.0.0"
}

module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.0"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "hpcc_demo"
  location            = "eastus2"
  environment         = "sandbox"
  product_name        = random_string.random.result
  business_unit       = "infra"
  product_group       = "hpcc"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v5.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  aks_subnets = {
    demo = {
      private = {
        cidrs = ["10.1.3.0/25"]
        service_endpoints = ["Microsoft.Storage"]
      }
      public = {
        cidrs = ["10.1.3.128/25"]
        service_endpoints = ["Microsoft.Storage"]
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          local-vnet-10-1-0-0-21 = {
            address_prefix = "10.1.0.0/21"
            next_hop_type  = "vnetlocal"
          }
        }
      }
    }
  }
}


# local updates made to support Kubernetes 1.21
module "aks" {
  source = "/home/jhodnett/repos/LN-RBA/terraform-azurerm-aks"

  cluster_name    = random_string.random.result
  cluster_version = "1.21"

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  node_pools = [
    {
      name            = "ingress"
      single_vmss     = true
      public          = true
      vm_size         = "medium"
      os_type         = "Linux"
      host_encryption = true
      min_count       = "1"
      max_count       = "2"
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      tags            = {}
    },
    {
      name            = "workers"
      single_vmss     = false
      public          = false
      vm_size         = "large"
      os_type         = "Linux"
      host_encryption = true
      min_count       = "1"
      max_count       = "2"
      taints          = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags            = {}
    }
  ]

  virtual_network = module.virtual_network.aks["demo"]

  core_services_config = merge({
    alertmanager = {
      smtp_host = var.smtp_host
      smtp_from = var.smtp_from
      receivers = [{ name = "alerts", email_configs = [{ to = var.alerts_mailto, require_tls = false }] }]
    }

    internal_ingress = {
      domain = "private.zone.azure.lnrsg.io"
    }

    external_dns = {
      zones               = ["us.lnrisk.io"]
      resource_group_name = "rg-iog-sandbox-eastus2-lnriskio"
    }
    cert_manager = {
      letsencrypt_environment = "staging"
      letsencrypt_email       = "James.Hodnett@lexisnexisrisk.com"
      dns_zones = {
        "us.lnrisk.io" = "rg-iog-sandbox-eastus2-lnriskio"
      }
    }
  }, var.config)

  # see /modules/core-config/modules/rbac/README.md
  azuread_clusterrole_map = {
    cluster_admin_users = {
      "hodnja01@risk.regn.net" = "fe33802a-25bf-4847-aa4e-85357dc91d8e"
      iog_dev_write            = "8d47c834-0c73-4467-9b79-783c1692c4e5"
    }
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

resource "kubernetes_namespace" "hpcc_namespace" {
  depends_on = [
    module.aks
  ]
  metadata {
    name = var.namespace
  }
}

resource "azurerm_storage_account" "storage_account" {
  depends_on = [
    kubernetes_namespace.hpcc_namespace
  ]

  name                = random_string.random.result
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  allow_blob_public_access = false
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"


  nfsv3_enabled             = true
  enable_https_traffic_only = true
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["${chomp(data.http.my_ip.body)}"]
    virtual_network_subnet_ids = [module.virtual_network.aks["demo"].subnets.private.id, module.virtual_network.aks["demo"].subnets.public.id]
    bypass                     = ["AzureServices"]
  }

}

resource "azurerm_storage_container" "hpcc_storage_containers" {
  for_each              = var.hpcc_storage
  name                  = "hpcc-data-${each.key}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "helm_release" "csi_driver" {
  depends_on = [
    module.aks,
    azurerm_storage_container.hpcc_storage_containers
  ]
  chart            = "blob-csi-driver"
  name             = "blob-csi-driver"
  namespace        = "blob-csi-driver"
  create_namespace = true
  repository       = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version          = "v1.3.0"
}

resource "random_uuid" "volume_handle" {}

resource "kubernetes_persistent_volume" "hpcc_blob_volumes" {
  depends_on = [
    kubernetes_namespace.hpcc_namespace,
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
          resourceGroup  = module.resource_group.name
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
    kubernetes_namespace.hpcc_namespace
  ]
  for_each = var.hpcc_storage
  metadata {
    name      = "pvc-blob-${each.key}-nfs"
    namespace = kubernetes_namespace.hpcc_namespace.metadata[0].name
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

locals {
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
}

resource "helm_release" "hpcc" {
  name             = "hpcc-demo"
  namespace        = kubernetes_namespace.hpcc_namespace.metadata[0].name
  create_namespace = true
  chart            = "hpcc"
  repository       = "https://hpcc-systems.github.io/helm-chart"
  version          = var.hpcc_helm_version
  values           = [templatefile("./hpcc_system_values.yaml.tpl", local.hpcc_config)]
}

