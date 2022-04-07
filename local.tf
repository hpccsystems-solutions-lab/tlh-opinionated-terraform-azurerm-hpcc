locals {
  create_registry_auth_secret = var.container_registry.username != null && var.container_registry.username != "" ? true : false

  internal_data_config = var.data_storage_config.internal == null ? false : true
  external_data_config = var.data_storage_config.external == null ? false : true

  create_data_storage = (local.internal_data_config ? (var.data_storage_config.internal.blob_nfs == null ? false : true) : false)
  create_data_cache   = (local.internal_data_config ? (var.data_storage_config.internal.hpc_cache == null ? false : true) : false)

  external_data_storage = (local.external_data_config ? (var.data_storage_config.external.blob_nfs == null ? false : true) : false)
  external_data_cache   = (local.external_data_config ? (var.data_storage_config.external.hpc_cache == null ? false : true) : false)
  external_hpcc_data    = (local.external_data_config ? (var.data_storage_config.external.hpcc == null ? false : true) : false)

  storage_config = {
    blob_nfs = (local.create_data_storage ? module.data_storage.0.data_planes : (
    local.external_data_storage ? var.data_storage_config.external.blob_nfs : null))
    hpc_cache = (local.create_data_cache ? module.data_cache.0.data_planes.default : (
    local.external_data_cache ? var.data_storage_config.external.hpc_cache : null))
    hpcc = local.external_hpcc_data ? var.data_storage_config.external.hpcc : []
  }

  blob_nfs_data_enabled  = local.storage_config.blob_nfs == null ? false : true
  hpc_cache_data_enabled = local.storage_config.hpc_cache == null ? false : true
  remote_data_enabled    = local.storage_config.hpcc == null ? false : true
  spill_space_enabled    = var.spill_volume_size == null ? false : true

  blob_nfs_data_storage = local.blob_nfs_data_enabled ? { for plane in local.storage_config.blob_nfs :
    "data-${plane.id}" => {
      category        = "data"
      container_name  = plane.container_name
      id              = plane.id
      path            = "hpcc-data"
      resource_group  = plane.resource_group_name
      storage_account = plane.storage_account_name
      size            = "5Pi"
    }
  } : {}

  hpc_cache_data_storage = local.hpc_cache_data_enabled ? { for plane in local.storage_config.hpc_cache :
    "data-${plane.id}" => {
      name   = "hpc-cache-data-${plane.id}"
      server = plane.server
      path   = plane.path
      size   = "5Pi"
    }
  } : {}

  services_storage_config = [
    {
      category       = "dali"
      container_name = "hpcc-dali"
      path           = "dalistorage"
      plane_name     = "dali"
      size           = var.services_storage_size.dali
    },
    {
      category       = "debug"
      container_name = "hpcc-debug"
      path           = "debug"
      plane_name     = "debug"
      size           = var.services_storage_size.debug
    },
    {
      category       = "dll"
      container_name = "hpcc-dll"
      path           = "queries"
      plane_name     = "dll"
      size           = var.services_storage_size.dll
    },
    {
      category       = "lz"
      container_name = "hpcc-mydropzone"
      path           = "mydropzone"
      plane_name     = "mydropzone"
      size           = var.services_storage_size.lz
    },
    {
      category       = "sasha"
      container_name = "hpcc-sasha"
      path           = "sashastorage"
      plane_name     = "sasha"
      size           = var.services_storage_size.sasha
    }
  ]

  blob_nfs_services_storage = { for config in local.services_storage_config :
    config.plane_name => {
      category        = config.category
      container_name  = config.container_name
      path            = config.path
      resource_group  = var.resource_group_name
      size            = config.size
      storage_account = azurerm_storage_account.services.name
    }
  }

  helm_chart_values = {

    global = {
      image = merge({
        version          = var.helm_chart_version
        root             = var.container_registry.image_root
        name             = var.container_registry.image_name
        pullPolicy       = "IfNotPresent"
        imagePullSecrets = local.create_registry_auth_secret ? kubernetes_secret.container_registry_auth.0.metadata.0.name : null
        },
      )
      visibilities = {
        cluster = {
          type = "ClusterIP"
        }
        local = {
          annotations = {
            "helm.sh/resource-policy"                                 = "keep"
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
          }
          type    = "LoadBalancer"
          ingress = []
        }
        global = {
          type    = "LoadBalancer"
          ingress = []
        }
      }
    }

    storage = merge({
      planes = concat([for k, v in local.blob_nfs_services_storage :
        {
          category = v.category
          name     = k
          prefix   = "/var/lib/HPCCSystems/${v.path}"
          pvc      = kubernetes_persistent_volume_claim.blob_nfs[k].metadata.0.name
        }
        ], local.blob_nfs_data_enabled ? [
        merge({
          category   = "data"
          name       = "data"
          numDevices = length(local.blob_nfs_data_storage)
          prefix     = "/var/lib/HPCCSystems/hpcc-data"
          pvc        = "pvc-blob-data"
          }, local.hpc_cache_data_enabled ? {
          aliases = [
            {
              mode      = [ "random" ]
              name      = "data-cache"
              numMounts = length(local.hpc_cache_data_storage)
              prefix    = "/var/lib/HPCCSystems/hpcc-data-cache"
              pvc       = "pvc-hpc-cache-data"
            }
          ]
        } : {})] : [], (local.hpc_cache_data_enabled && !local.blob_nfs_data_enabled) ? [
        {
          category   = "data"
          name       = "data"
          numDevices = length(local.hpc_cache_data_storage)
          prefix     = "/var/lib/HPCCSystems/hpcc-data"
          pvc        = "pvc-hpc-cache-data"
        }
        ] : [], local.spill_space_enabled ? [
        {
          category         = "spill"
          name             = "localspill"
          prefix           = "/var/lib/HPCCSystems/spill"
          pvc              = "pvc-spill"
          forcePermissions = true
        }
        ] : []
      ) }, local.external_hpcc_data ? { remote = local.storage_config.hpcc } : {}
    )

    certificates = {
      enabled = false
      issuers = {
        local = {
          name = "letsencrypt-issuer"
          kind = "ClusterIssuer"
          spec = null
        }
      }
    }

    eclagent = [
      {
        name      = "hthor"
        replicas  = 1
        maxActive = 4
      },
      {
        name      = "roxie-workunit"
        replicas  = 1
        maxActive = 4
      }
    ]

    eclccserver = [
      {
        name      = "myeclccserver"
        replicas  = 1
        maxActive = 4
      }
    ]

    esp = [
      {
        name        = "eclwatch"
        application = "eclwatch"
        auth        = "none"
        replicas    = 1
        service = {
          port        = 8888
          servicePort = 8010
          visibility  = "local"
        }
      },
      {
        name        = "eclservices"
        application = "eclservices"
        auth        = "none"
        replicas    = 1
        service = {
          servicePort = 8010
          visibility  = "cluster"
        }
      },
      {
        name        = "eclqueries"
        application = "eclqueries"
        auth        = "none"
        replicas    = 1
        service = {
          servicePort = 8002
          visibility  = "local"
        }
      },
      {
        name        = "esdl-sandbox"
        application = "esdl-sandbox"
        auth        = "none"
        replicas    = 1
        service = {
          servicePort = 8899
          visibility  = "local"
        }
      },
      {
        name        = "sql2ecl"
        application = "sql2ecl"
        auth        = "none"
        replicas    = 1
        service = {
          servicePort = 8510
          visibility  = "local"
        }
      }
    ]

    roxie = var.roxie_config

    thor = var.thor_config

    eclscheduler = [
      {
        name = "eclscheduler"
      }
    ]
  }

}