# Random string for resource group 

resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

resource "random_password" "elastic_password" {
  length  = 12
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
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"

  cluster_name    = random_string.random.result
  cluster_version = "1.21"

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  node_pools = [
    {
      name         = "ingress"
      single_vmss  = true
      public       = true
      node_type    = "x64-gp"
      node_size    = "medium"
      min_capacity = 1
      max_capacity = 2
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      tags         = {}
    },
    {
      name         = "workers"
      single_vmss  = false
      public       = false
      node_type    = "x64-gp"
      node_size    = "large"
      min_capacity = 1
      max_capacity = 2
      taints       = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags         = {}
    }
  ]
  
  virtual_network = module.virtual_network.aks["demo"]

  core_services_config = merge({
    alertmanager = {
      smtp_host = var.smtp_host
      smtp_from = var.smtp_from
      receivers = [{ name = "alerts", email_configs = [{ to = var.alerts_mailto, require_tls = false }] }]
    }

    ingress_internal_core = {
      domain = "infrastructure-sandbox.us.lnrisk.io"
    }

    external_dns = {
      zones               = ["infrastructure-sandbox.us.lnrisk.io"]
      resource_group_name = "rg-iog-sandbox-eastus2-lnriskio"
    }
    cert_manager = {
      letsencrypt_environment = "staging"
      letsencrypt_email       = "James.Hodnett@lexisnexisrisk.com"
      dns_zones = {
        "infrastructure-sandbox.us.lnrisk.io" = "rg-iog-sandbox-eastus2-lnriskio"
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

resource "kubernetes_namespace" "hpcc_namespaces" {
  depends_on = [
    module.aks
  ]

  for_each = toset(var.hpcc_namespaces)

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

resource "kubernetes_secret" "hpcc_secrets" {
  depends_on = [
    module.aks,
    kubernetes_namespace.hpcc_namespaces
  ]

  for_each = local.hpcc_secrets

  metadata {
    name       = each.value.name
    namespace  = each.value.namespace
  }

  type = each.value.type
  data = each.value.data
}

resource "azurerm_storage_account" "storage_account" {
  depends_on = [
    module.aks
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
  enable_https_traffic_only = false
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
  name                  = "hpcc-${each.key}"
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
  repository       = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version          = "v1.3.0"
}

resource "helm_release" "elasticsearch" {
  depends_on = [
    module.aks,
    azurerm_storage_container.hpcc_storage_containers
  ]
  chart            = "elasticsearch"
  name             = "elasticsearch"
  namespace        = "elasticsearch"
  repository       = "https://helm.elastic.co/"
  version          = "v7.13.4"
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
    module.aks
  ]
  for_each = var.hpcc_storage
  metadata {
    name      = "pvc-blob-${each.key}-nfs"
    namespace = "hpcc-demo"
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
  depends_on = [
    module.aks
  ]
  name             = "hpcc-demo"
  namespace        = "hpcc-demo"
  chart            = "hpcc"
  repository       = "https://hpcc-systems.github.io/helm-chart"
  version          = var.hpcc_helm_version
  values           = [templatefile("./hpcc_system_values.yaml.tpl", local.hpcc_config)]
}

