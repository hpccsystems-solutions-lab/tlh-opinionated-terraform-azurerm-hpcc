locals {
  create_hpcc_registry_auth_secret = var.hpcc_container_registry_auth != null ? true : false

  
  internal_data_config = var.data_storage_config.internal == null ? false : true
  external_data_config = var.data_storage_config.external == null ? false : true

  create_data_storage = (local.internal_data_config ? (var.data_storage_config.internal.blob_nfs == null ? false : true) : false)
  create_data_cache   = (local.internal_data_config ? (var.data_storage_config.internal.hpc_cache == null ? false : true) : false)

  external_data_storage = (local.external_data_config ? (var.data_storage_config.external.blob_nfs == null ? false : true) : false)
  external_data_cache   = (local.external_data_config ? (var.data_storage_config.external.hpc_cache == null ? false : true) : false)
  external_hpcc_data    = (local.external_data_config ? (var.data_storage_config.external.hpcc == null ? false : true) : false)

  storage_config = {
    blob_nfs = (local.create_data_storage ? module.data_storage.0.data_planes : (
      local.external_data_storage ? var.data_storage_config.external.blob_nfs : null)
    )
    hpc_cache = (local.create_data_cache ? module.data_cache.0.data_planes.internal : (
      local.external_data_cache ? var.data_storage_config.external.hpc_cache : null)
    )
    hpcc = local.external_hpcc_data ? var.data_storage_config.external.hpcc : []
  }

  blob_nfs_data_enabled  = local.storage_config.blob_nfs == null ? false : true
  hpc_cache_data_enabled = local.storage_config.hpc_cache == null ? false : true
  remote_data_enabled    = local.storage_config.hpcc == null ? false : true
  spill_space_enabled    = var.spill_volume_size == null ? false : true

  blob_nfs_data_storage = local.blob_nfs_data_enabled ? { for plane in local.storage_config.blob_nfs :
    length(local.storage_config.blob_nfs) == 1 ? "data" : "data-${plane.id}" => {
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
    length(local.storage_config.hpc_cache) == 1 ? "data" : "data-${plane.id}" => {
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
      size           = var.admin_services_storage_size.dali
    },
    {
      category       = "debug"
      container_name = "hpcc-debug"
      path           = "debug"
      plane_name     = "debug"
      size           = var.admin_services_storage_size.debug
    },
    {
      category       = "dll"
      container_name = "hpcc-dll"
      path           = "queries"
      plane_name     = "dll"
      size           = var.admin_services_storage_size.dll
    },
    {
      category       = "lz"
      container_name = "hpcc-mydropzone"
      path           = "mydropzone"
      plane_name     = "mydropzone"
      size           = var.admin_services_storage_size.lz
    },
    {
      category       = "sasha"
      container_name = "hpcc-sasha"
      path           = "sashastorage"
      plane_name     = "sasha"
      size           = var.admin_services_storage_size.sasha
    }
  ]

  blob_nfs_services_storage = { for config in local.services_storage_config :
    config.plane_name => {
      category        = config.category
      container_name  = config.container_name
      path            = config.path
      resource_group  = var.resource_group_name
      size            = config.size
      storage_account = azurerm_storage_account.admin_services.name
    }
  }

  ldap_defaults = {
    serverType     = "ActiveDirectory"
    description    = "LDAP server process"
    ldapProtocol   = "ldaps"
    ldapPort       = 389
    ldapSecurePort = 636
  }

  ldap_enabled         = var.ldap_config == null ? false : true
  ldap_shared_config   = local.ldap_enabled ? merge({ ldapAddress = var.ldap_config.ldap_server }, var.ldap_tunables, local.ldap_defaults) : null
  ldap_config_excludes = ["hpcc_admin_password", "hpcc_admin_username", "ldap_admin_password", "ldap_admin_username"]

  dali_ldap_config = local.ldap_enabled ? { ldap = merge(
    { for k, v in var.ldap_config.dali : k => v if !contains(local.ldap_config_excludes, k) },
    { hpccAdminSecretKey = "dali-hpccadminsecretkey", ldapAdminSecretKey = "dali-ldapadminsecretkey" },
    local.ldap_shared_config
  )} : null

  esp_ldap_config = local.ldap_enabled ? { ldap = merge(
    { for k, v in var.ldap_config.esp : k => v if !contains(local.ldap_config_excludes, k) },
    { ldapAdminSecretKey = "esp-ldapadminsecretkey" },
    local.ldap_shared_config
  )} : null

  auth_mode            = local.ldap_enabled ? "ldap" : "none"
  authn_secrets = local.ldap_enabled ? {
    authn = { 
      dali-hpccadminsecretkey = kubernetes_secret.dali_hpcc_admin.0.metadata.0.name 
      dali-ldapadminsecretkey = kubernetes_secret.dali_ldap_admin.0.metadata.0.name 
      esp-ldapadminsecretkey  = kubernetes_secret.esp_ldap_admin.0.metadata.0.name 
    }
  } : null

  helm_chart_values = {

    global = {
      image = merge({
        version    = var.hpcc_container.version == null ? var.helm_chart_version : var.hpcc_container.version
        root       = var.hpcc_container.image_root
        name       = var.hpcc_container.image_name
        pullPolicy = "IfNotPresent"
      }, local.create_hpcc_registry_auth_secret ? { imagePullSecrets = kubernetes_secret.hpcc_container_registry_auth.0.metadata.0.name } : {})
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
              mode      = ["random"]
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

    dali = [
      merge({
        name = "mydali"
        auth = local.auth_mode
        services = {
          coalescer = {
            service = {
              servicePort = 8877
            }
          }
        }
      }, local.dali_ldap_config)
    ]

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
      merge({
        name        = "eclwatch"
        application = "eclwatch"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          port        = 8888
          servicePort = 8010
          visibility  = "local"
        }
      }, local.esp_ldap_config),
      merge({
        name        = "eclservices"
        application = "eclservices"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 8010
          visibility  = "cluster"
        }
      }, local.esp_ldap_config),
      merge({
        name        = "eclqueries"
        application = "eclqueries"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 8002
          visibility  = "local"
        }
      }, local.esp_ldap_config),
      merge({
        name        = "esdl-sandbox"
        application = "esdl-sandbox"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 8899
          visibility  = "local"
        }
      }, local.esp_ldap_config),
      merge({
        name        = "sql2ecl"
        application = "sql2ecl"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 8510
          visibility  = "local"
        }
      }, local.esp_ldap_config)
    ]

    roxie = var.roxie_config

    thor = var.thor_config

    eclscheduler = [
      {
        name = "eclscheduler"
      }
    ]

    secrets = merge(
      local.ldap_enabled ? local.authn_secrets : null
    )

  }

}