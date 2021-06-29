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
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v1.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v2.10.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  aks_subnets = {
    private = {
      cidrs = ["10.1.0.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    public = {
      cidrs = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    route_table = "default"
  }

  route_tables = {
    default = {
      disable_bgp_route_propagation = true
      use_inline_routes             = false
      routes = {
        internet = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "Internet"
        }
        local-vnet-10-1-0-0-22 = {
          address_prefix         = "10.1.0.0/22"
          next_hop_type          = "vnetlocal"
        }
      }
    }
  }
}


# local updates made to support Kubernetes 1.21
module "aks" {
  source = "/home/jhodnett/repos/LN-RBA/terraform-azurerm-aks"

  cluster_name = random_string.random.result
  cluster_version = "1.21"

  location            = module.metadata.location
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name

  external_dns_zones     = var.external_dns_zones
  cert_manager_dns_zones = var.cert_manager_dns_zones

  node_pool_tags     = {}
  node_pool_defaults = {}
  node_pool_taints   = {}

  node_pools = [
    {
      name      = "private"
      tier      = "standard"
      lifecycle = "normal"
      vm_size   = "large"
      os_type   = "Linux"
      min_count = "1"
      max_count = "2"
      labels    = {}
      tags      = {}
    },
    {
      name      = "public"
      tier      = "ingress"
      lifecycle = "normal"
      vm_size   = "medium"
      os_type   = "Linux"
      min_count = "1"
      max_count = "2"
      labels    = {}
      tags      = {}
    }
  ]

  virtual_network = {
    subnets = {
      private = module.virtual_network.aks_subnets.private
      public  = module.virtual_network.aks_subnets.public
    }
    route_table_id = module.virtual_network.aks_subnets.route_table_id
  }

  config = {
    alertmanager = {
      smtp_host = var.smtp_host
      smtp_from = var.smtp_from
      receivers = [{ name = "alerts", email_configs = [{ to = var.alerts_mailto, require_tls = false }]}]
    }

    internal_ingress = {
      domain    = "private.zone.azure.lnrsg.io"
    }
  }

  # see /modules/core-config/modules/rbac/README.md
  azuread_clusterrole_map = {
    cluster_admin_users  = {
      "hodnja01@risk.regn.net" = "fe33802a-25bf-4847-aa4e-85357dc91d8e"
      iog_dev_write = "8d47c834-0c73-4467-9b79-783c1692c4e5"
    }
    cluster_view_users = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

resource "kubernetes_namespace" "hpcc_namespace" {
  metadata {
    name = var.namespace
  }
}

resource "azurerm_storage_account" "storage_account" {
  
  name                       = "${random_string.random.result}"
  resource_group_name        = data.azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  location                   = module.resource_group.location
  tags                       = module.metadata.tags

  access_tier                = "Hot"
  account_kind               = "StorageV2"
  account_tier               = "Standard"
  allow_blob_public_access   = true
  is_hns_enabled             = true
  min_tls_version            = "TLS1_2"


  nfsv3_enabled              = true
  enable_https_traffic_only  = false

  account_replication_type   = "LRS"

  network_rules {
    default_action              = "Deny"
    ip_rules                    = ["${chomp(data.http.my_ip.body)}"]
    virtual_network_subnet_ids  = [module.virtual_network.aks_subnets.private.id, module.virtual_network.aks_subnets.public.id]
    bypass                      = ["AzureServices"]
  }

}

resource "azurerm_storage_container" "hpcc_data" {
  name = "hpcc-data"
  storage_account_name = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "helm_release" "csi_driver" {
  depends_on = [
    module.aks
  ]
  chart = "blob-csi-driver"
  name = "blob-csi-driver"
  namespace = "blob-csi-driver"
  create_namespace = true
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version = "v1.3.0"
}

resource "random_uuid" "volume_handle" {}

resource "kubernetes_persistent_volume" "hpcc_data_blob_volume" {
  metadata {
    name = "pv-blob"
    labels = {
      storage-tier = "blobnfs"
    }
  }

  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteMany"]
    
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      csi {
        driver = "blob.csi.azure.com"
        read_only = false
        volume_handle = random_uuid.volume_handle.result
        volume_attributes = {
          resourceGroup = data.azurerm_kubernetes_cluster.aks_cluster.node_resource_group 
          storageAccount = azurerm_storage_account.storage_account.name
          containerName = azurerm_storage_container.hpcc_data.name
          protocol = "nfs"
        }
      }
    }

    storage_class_name = "blobnfs"
  }
} 

resource kubernetes_persistent_volume_claim "hpcc_data_blob_pvc" {
  metadata {
    name = "pvc-blob-nfs"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "blobnfs"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    selector {
      match_labels = {
        storage-tier = "blobnfs"
      }
    }   
    volume_name = kubernetes_persistent_volume.hpcc_data_blob_volume.metadata.0.name
  }
}

module hpcc_system {
  source = "../.."

  namespace = var.namespace
  name = "hpcc-demo"

  hpcc_storage_values = ["${file("./hpcc_storage_values.yaml")}"]
  hpcc_system_values = ["${file("./hpcc_system_values.yaml")}"]
  
}