locals {
  create_hpcc_registry_auth_secret = var.hpcc_container_registry_auth != null ? true : false

  azurefiles_admin_storage_enabled = contains([for storage in var.admin_services_storage : storage.type], "azurefiles")
  blobnfs_admin_storage_enabled    = contains([for storage in var.admin_services_storage : storage.type], "blobnfs")

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
      size           = "${var.admin_services_storage.dali.size}G"
      storage_type   = var.admin_services_storage.dali.type
    },
    {
      category       = "debug"
      container_name = "hpcc-debug"
      path           = "debug"
      plane_name     = "debug"
      size           = "${var.admin_services_storage.debug.size}G"
      storage_type   = var.admin_services_storage.debug.type
    },
    {
      category       = "dll"
      container_name = "hpcc-dll"
      path           = "queries"
      plane_name     = "dll"
      size           = "${var.admin_services_storage.dll.size}G"
      storage_type   = var.admin_services_storage.dll.type
    },
    {
      category       = "lz"
      container_name = "hpcc-mydropzone"
      path           = "mydropzone"
      plane_name     = "mydropzone"
      size           = "${var.admin_services_storage.lz.size}G"
      storage_type   = var.admin_services_storage.lz.type
    },
    {
      category       = "sasha"
      container_name = "hpcc-sasha"
      path           = "sashastorage"
      plane_name     = "sasha"
      size           = "${var.admin_services_storage.sasha.size}G"
      storage_type   = var.admin_services_storage.sasha.type
    }
  ]

  azurefiles_services_storage = { for config in local.services_storage_config :
    config.plane_name => {
      category        = config.category
      container_name  = config.container_name
      path            = config.path
      resource_group  = var.resource_group_name
      size            = config.size
      storage_account = azurerm_storage_account.azurefiles_admin_services.0.name
    } if config.storage_type == "azurefiles"
  }

  blob_nfs_services_storage = { for config in local.services_storage_config :
    config.plane_name => {
      category        = config.category
      container_name  = config.container_name
      path            = config.path
      resource_group  = var.resource_group_name
      size            = config.size
      storage_account = azurerm_storage_account.blob_nfs_admin_services.0.name
    } if config.storage_type == "blobnfs"
  }

  ldap_defaults = {
    serverType     = "ActiveDirectory"
    description    = "LDAP server process"
    ldapProtocol   = "ldaps"
    ldapPort       = 389
    ldapSecurePort = 636
  }

  ldap_enabled = var.ldap_config == null ? false : true

  auth_mode = local.ldap_enabled ? "ldap" : "none"
  ldap_authn_secrets = local.ldap_enabled ? {
    dali-hpccadminsecretkey = kubernetes_secret.dali_hpcc_admin.0.metadata.0.name
    dali-ldapadminsecretkey = kubernetes_secret.dali_ldap_admin.0.metadata.0.name
    esp-ldapadminsecretkey  = kubernetes_secret.esp_ldap_admin.0.metadata.0.name
  } : null

  ldap_shared_config   = local.ldap_enabled ? merge({ ldapAddress = var.ldap_config.ldap_server }, var.ldap_tunables, local.ldap_defaults) : null
  ldap_config_excludes = ["hpcc_admin_password", "hpcc_admin_username", "ldap_admin_password", "ldap_admin_username"]

  dali_ldap_config = local.ldap_enabled ? { ldap = merge(
    { for k, v in var.ldap_config.dali : k => v if !contains(local.ldap_config_excludes, k) },
    { hpccAdminSecretKey = "dali-hpccadminsecretkey", ldapAdminSecretKey = "dali-ldapadminsecretkey" },
    local.ldap_shared_config
  ) } : null

  esp_ldap_config = local.ldap_enabled ? { ldap = merge(
    { for k, v in var.ldap_config.esp : k => v if !contains(local.ldap_config_excludes, k) },
    { ldapAdminSecretKey = "esp-ldapadminsecretkey" },
    local.ldap_shared_config
  ) } : null

  enabled_roxie_configs = { for roxie in var.roxie_config : roxie.name => roxie if !roxie.disabled }

  roxie_config_excludes = ["nodeSelector"]
  roxie_config = [for roxie in var.roxie_config :
    { for k, v in roxie : k => v if !contains(local.roxie_config_excludes, k) }
  ]

  thor_config_excludes = ["nodeSelector"]
  thor_config = [for thor in var.thor_config :
    { for k, v in thor : k => v if !contains(local.thor_config_excludes, k) }
  ]

  admin_placements = [for k, v in var.admin_services_node_selector :
    ( k == "all" ? { pods = ["${k}"], placement = { nodeSelector = v } } :
                   { pods = ["type:${k}"], placement = { nodeSelector = v } } )
  ]

  roxie_placements = [for roxie in var.roxie_config :
    { pods = ["target:${roxie.name}"], placement = { nodeSelector = roxie.nodeSelector } } if length(roxie.nodeSelector) > 0
  ]

  thor_placements = [for thor in var.thor_config :
    { pods = ["target:${thor.name}"], placement = { nodeSelector = thor.nodeSelector } } if length(thor.nodeSelector) > 0
  ]

  placements = concat(local.admin_placements, local.roxie_placements, local.thor_placements)

  helm_chart_values = {

    global = {
      env = [ for k,v in var.environment_variables: { name = k, value = v} ]
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
        ],
        [for k, v in local.azurefiles_services_storage :
          {
            category = v.category
            name     = k
            prefix   = "/var/lib/HPCCSystems/${v.path}"
            pvc      = kubernetes_persistent_volume_claim.azurefiles[k].metadata.0.name
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

    placements = local.placements

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

    roxie = local.roxie_config

    thor = local.thor_config

    eclscheduler = [
      {
        name = "eclscheduler"
      }
    ]

    secrets = {
      authn      = merge(local.ldap_authn_secrets, {})
      codeSign   = {}
      codeVerify = {}
      ecl        = {}
      git        = {}
      storage    = {}
      system     = {}
    }

  }

}