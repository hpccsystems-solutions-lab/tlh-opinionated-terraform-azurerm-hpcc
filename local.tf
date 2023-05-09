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

  acr_default = var.node_tuning_containers == null ? {
    busybox = format("%s%scr.azurecr.io/hpccoperations/busybox:latest", var.productname, var.environment)
    debian  = format("%s%scr.azurecr.io/hpccoperations/debian:bullseye-slim", var.productname, var.environment)
  } : var.node_tuning_containers

  external_dns_zone_enabled = var.internal_domain != null
  domain                    = coalesce(var.internal_domain, format("us-%s.%s.azure.lnrsg.io", var.productname, var.environment))
  account_code              = split(".", local.domain)[0]
  aks_trimmed_name          = trimprefix(var.cluster_name, "${local.account_code}-")


  azure_files_pv_protocol = var.environment == "dev" ? "nfs" : null
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
  spill_space_enabled    = length(var.spill_volumes) > 0 ? true : false

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
      protocol        = local.azure_files_pv_protocol
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

  eclccserver_settings = [for k, v in var.eclccserver_settings : {
    name                  = k
    replicas              = v.replicas
    useChildProcesses     = v.useChildProcesses
    childProcessTimeLimit = v.childProcessTimeLimit
    maxActive             = v.maxActive
    resources             = v.resources
    egress                = v.egress
    listen                = v.listen_queue
    gitUsername           = v.gitUsername
    defaultRepo           = v.defaultRepo
    defaultRepoVersion    = v.defaultRepoVersion
    options               = v.legacySyntax != false ? concat([{ name = "eclcc-legacyimport", value = 1 }, { name = "eclcc-legacywhen", value = 1 }], v.options) : v.options
  }]

  ldap_defaults = {
    serverType     = "ActiveDirectory"
    description    = "LDAP server process"
    ldapProtocol   = "ldaps"
    ldapPort       = 389
    ldapSecurePort = 636
  }



  # Vault Secrets Section
  vault_enabled = var.vault_config == null && var.vault_config != null ? false : true

  all_vault_secrets = local.vault_enabled ? values(merge(var.vault_secrets.ecluser_approle_secret, var.vault_secrets.ecl_approle_secret, var.vault_secrets.git_approle_secret, var.vault_secrets.esp_approle_secret)) : []

  vault_secrets = local.vault_enabled ? { for k in local.all_vault_secrets : k.secret_name => k.secret_name

  } : null


  vault_git_config = var.vault_config.git != null ? [for k, v in var.vault_config.git : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null

  vault_ecl_config = var.vault_config.ecl != null ? [for k, v in var.vault_config.ecl : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null

  vault_ecluser_config = var.vault_config.ecluser != null ? [for k, v in var.vault_config.ecluser : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null

  vault_esp_config = var.vault_config.esp != null ? [for k, v in var.vault_config.esp : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null

  # LDAP Secrets section 
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

  eclagent_settings = [for k, v in var.eclagent_settings : {
    name              = k
    replicas          = v.replicas
    maxActive         = v.maxActive
    prefix            = v.prefix
    useChildProcesses = v.use_child_process
    type              = v.type
    resources         = v.resources
    egress            = v.egress
    spillPlane       = v.spillPlane
  }]

  roxie_config_excludes = ["nodeSelector"]
  roxie_config = [for roxie in var.roxie_config :
    { for k, v in roxie : k => v if !contains(local.roxie_config_excludes, k) }
  ]

  thor_config_excludes = ["nodeSelector"]
  thor_config = [for thor in var.thor_config :
    { for k, v in thor : k => v if !contains(local.thor_config_excludes, k) }
  ]

  admin_placements = [for k, v in var.admin_services_node_selector :
    (k == "all" ? { pods = ["${k}"], placement = { nodeSelector = v } } :
    { pods = ["type:${k}"], placement = { nodeSelector = v } })
  ]

  roxie_placements = [for roxie in var.roxie_config :
    { pods = ["target:${roxie.name}"], placement = { nodeSelector = roxie.nodeSelector } } if length(roxie.nodeSelector) > 0
  ]

  thor_placements = [for thor in var.thor_config :
    { pods = ["target:${thor.name}"],
      placement = merge({ nodeSelector = thor.nodeSelector },
        { tolerations = [{
          key      = "hpcc"
          operator = "Equal"
          value    = thor.tolerations_value
          effect   = "NoSchedule"
      }] })
    } if length(thor.nodeSelector) > 0
  ]

  placements_tolerations = [
    {
      pods = ["all"]
      placement = {
        tolerations = [
          {
            key      = "hpcc"
            operator = "Equal"
            value    = "servpool"
            effect   = "NoSchedule"
          }
        ]
      }
    },
    {
      pods = ["spray-service"]
      placement = {

        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key      = "workload"
                      operator = "In"
                      values   = ["spraypool"]
                    }
                  ]
                }
              ]
            }
          }
        }
        nodeSelector = {
          workload = var.spray_service_settings.nodeSelector
        }
        tolerations = [
          {
            key      = "hpcc"
            operator = "Equal"
            value    = "spraypool"
            effect   = "NoSchedule"
          }
        ]
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.spray-service.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "spray-service"
              }
            }
          }
        ]
      }
    },
    {
      pods = ["eclwatch"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.eclwatch.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "eclwatch"
              }
            }
          }
        ]
      }
    },

    {
      pods = ["eclservices"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.eclservices.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "eclservices"
              }
            }
          }
        ]
      }
    },

    {
      pods = ["eclqueries"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.eclqueries.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "eclqueries"
              }
            }
          }
        ]
      }
    },

    {
      pods = ["dfs"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.dfs.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "dfs"
              }
            }
          }
        ]
      }
    },

    {
      pods = ["direct-access"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.direct-access.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "direct-access"
              }
            }
          }
        ]
      }
    },

    {
      pods = ["thorworker"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.thorworker.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "thorworker"
              }
            }
          }
        ]
      }
    },

    {
      pods = ["roxie-agent"]
      placement = {
        topologySpreadConstraints = [
          {
            maxSkew           = var.placements.roxie-agent.maxskew
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                server = "roxie-agent"
              }
            }
          }
        ]
      }
    }

  ]

  placements = concat(local.admin_placements, local.roxie_placements, local.thor_placements, local.placements_tolerations)

  remote_storage_enabled = var.remote_storage_plane == null ? false : true

  remote_storage_plane = local.remote_storage_enabled ? flatten([
    for subscription_key, subscription_val in var.remote_storage_plane : [
      for sa_key, sa_val in subscription_val.target_storage_accounts : {
        subscription_name      = subscription_key
        dfs_service_name       = subscription_val.dfs_service_name
        storage_account_name   = sa_val.name
        storage_account_prefix = sa_val.prefix
        storage_account_key    = sa_key
        volume_name            = format("%s-remote-hpcc-data-%s", subscription_key, index(keys(subscription_val.target_storage_accounts), sa_key) + 1)
        volume_claim_name      = format("%s-remote-hpcc-data-%s", subscription_key, index(keys(subscription_val.target_storage_accounts), sa_key) + 1)
      }
    ]
  ]) : []

  remote_storage_helm_values = local.remote_storage_enabled ? { for k, v in var.remote_storage_plane : k => {
    dfs_service_name = v.dfs_service_name
    numDevices       = length(v.target_storage_accounts)
  } } : null

  onprem_lz_enabled = var.onprem_lz_settings == null ? false : true

  onprem_lz_helm_values = local.onprem_lz_enabled ? [for k, v in var.onprem_lz_settings : {
    category = "lz"
    name     = k
    prefix   = v.prefix
    hosts    = v.hosts
  }] : null

  corsAllowed = [
    {
      origin  = var.corsAllowed.origin
      headers = var.corsAllowed.headers
      methods = var.corsAllowed.methods
    }
  ]
  helm_chart_values = {

    global = {
      env = [for k, v in var.environment_variables : { name = k, value = v }]
      expert = {
        numRenameRetries = var.global_num_rename_retries
        maxConnections   = var.global_max_connections
        keepalive = {
          interval = var.keepalive_settings.interval
          probes   = var.keepalive_settings.probes
          time     = var.keepalive_settings.time
        }
      }
      busybox = local.acr_default.busybox
      image = merge({
        version    = var.hpcc_container.version == null ? var.helm_chart_version : var.hpcc_container.version
        root       = var.hpcc_container.image_root
        name       = var.hpcc_container.image_name
        pullPolicy = "IfNotPresent"
      }, local.create_hpcc_registry_auth_secret ? { imagePullSecrets = kubernetes_secret.hpcc_container_registry_auth.0.metadata.0.name } : {})

      # Log Analytics Integration Values
      logAccess = {
        name = "Azure LogAnalytics LogAccess"
        type = "AzureLogAnalyticsCurl"
        logMaps = [{
          type            = "global"
          storeName       = "ContainerLog"
          searchColumn    = "LogEntry"
          timeStampColumn = "hpcc_log_timestamp"
          }, {
          type         = "workunits"
          storeName    = "ContainerLog"
          searchColumn = "hpcc_log_jobid"
          }, {
          type            = "components"
          storeName       = "ContainerInventory"
          searchColumn    = "Name"
          keyColumn       = "ContainerID"
          timeStampColumn = "TimeGenerated"
          }, {
          type         = "audience"
          searchColumn = "hpcc_log_audience"
          }, {
          type         = "class"
          searchColumn = "hpcc_log_class"
          }, {
          type         = "instance"
          storeName    = "ContainerInventory"
          searchColumn = "Name"
          }, {
          type         = "host"
          searchColumn = "Computer"
        }]
      }



      # Egress Values 
      egress = var.egress_engine

      visibilities = {
        cluster = {
          type = "ClusterIP"
        }
        local = {
          annotations = {
            "helm.sh/resource-policy"                                 = "keep"
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
          }
          type = "LoadBalancer"
          ingress = [
            {}
          ]
        }
        global = {
          type = "LoadBalancer"
          ingress = [
            {}
          ]
        }
      }

      cost = {
        currencyCode  = "USD"
        perCpu        = var.cost.perCpu
        storageAtRest = var.cost.storageAtRest
        storageReads  = var.cost.storageReads
        storageWrites = var.cost.storageWrites
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
          ] : [], local.spill_space_enabled ? [for k, v in var.spill_volumes : {
            category         = "spill"
            name             = v.name
            prefix           = v.prefix
            pvc              = "${var.namespace.name}-pvc-${v.name}"
            forcePermissions = true
          }
          ] : [], local.onprem_lz_enabled ? local.onprem_lz_helm_values : [], [ # L Series Spill Stuff
          {
            category         = "spill"
            name             = "local-spill-pvc1"
            prefix           = "/var/lib/HPCCSystems/spilla"
            storageClass     = "local-storage"
            storageSize     = "1759Gi"
          },
          {
            category         = "spill"
            name             = "local-spill-pvc2"
            prefix           = "/var/lib/HPCCSystems/spillb"
            storageClass     = "local-disk"
            storageSize     = "3500Gi"
            storageMode     = "ReadWriteOnce"
          },
        ],
        local.remote_storage_enabled ? [for k, v in local.remote_storage_helm_values :
          {
            category   = "remote"
            prefix     = format("/var/lib/HPCCSystems/%s-data", k)
            name       = format("%s-remote-hpcc-data", k)
            pvc        = format("%s-remote-hpcc-data", k)
            numDevices = v.numDevices
            secret     = var.secrets.remote_cert_secret
          }
        ] : []
        ) }, local.remote_storage_enabled ? { remote = [for k, v in local.remote_storage_helm_values : {
          name    = format("%s-data", k)
          service = v.dfs_service_name
          planes = [
            {
              remote = "data"
              local  = format("%s-remote-hpcc-data", k)
            }
          ]
      }] } : {}, local.external_hpcc_data ? { remote = local.storage_config.hpcc } : {},
    )

    certificates = {
      enabled = true
      issuers = {
        local = {
          name   = "hpcc-local-issuer"
          kind   = "Issuer"
          domain = var.internal_domain
          spec = {
            ca = {
              secretName = "hpcc-local-issuer-key-pair"
            }
          }
        }
        public = {
          name   = "hpcc-public-issuer"
          kind   = "Issuer"
          domain = var.internal_domain
          spec = {
            selfSigned = {}
          }
        }
        remote = {
          enabled = true
          name    = "hpcc-remote-issuer"
          kind    = "Issuer"
          domain  = var.internal_domain
          spec = {
            ca = {
              secretName = "hpcc-remote-issuer-key-pair"
            }
          }
        }
        signing = {
          name = "hpcc-signing-issuer"
          kind = "Issuer"
          spec = {
            ca = {
              secretName = "hpcc-signing-issuer-key-pair"
            }
          }
        }
      }
    }

    placements = local.placements

    dafilesrv = [
      {
        name        = "direct-access"
        application = "directio"
        disabled    = var.disable_directio
        service = {
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "directio", var.namespace.name, local.domain) } : {})
        }
        egress = var.egress.dafilesrv_engine
      },
      {
        name        = "spray-service"
        application = "spray"
        replicas    = var.spray_service_settings.replicas
        service = {
          servicePort = 7300 ##443
          visibility  = "cluster"
        }
        egress = var.egress.dafilesrv_engine
      },
      {
        name        = "rowservice"
        application = "stream"
        disabled    = var.disable_rowservice
        service = {
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "rowservice", var.namespace.name, local.domain) } : {})
        }
        egress = var.egress.dafilesrv_engine
      }
    ]

    dali = [
      merge({
        name = "mydali"
        auth = local.auth_mode
        services = {
          coalescer = {
            service = {
              servicePort = 8877
            }
            interval     = var.dali_settings.coalescer.interval
            at           = var.dali_settings.coalescer.at
            minDeltaSize = var.dali_settings.coalescer.minDeltaSize
            resources = {
              cpu    = var.dali_settings.coalescer.resources.cpu
              memory = var.dali_settings.coalescer.resources.memory
            }
          }
        }
        resources = {
          cpu    = var.dali_settings.resources.cpu
          memory = var.dali_settings.resources.memory
        }
        egress = var.egress.dali_engine
      }, local.dali_ldap_config)
    ]

    dfuserver = [
      {
        name    = "dfuserver"
        maxJobs = var.dfuserver_settings.maxJobs
        resources = {
          cpu    = var.dfuserver_settings.resources.cpu
          memory = var.dfuserver_settings.resources.memory
        }
        egress = var.egress.dfuserver_name
      }
    ]

    eclagent = local.eclagent_settings


    eclccserver = local.eclccserver_settings

    esp = [
      merge({
        name          = "dfs"
        application   = "dfs"
        remoteClients = var.esp_remoteclients
        auth          = "none"
        replicas      = 1
        service = {
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "dfs", var.namespace.name, local.domain) } : {})
        }
        egress = var.egress.esp_engine
      }, local.esp_ldap_config),
      merge({
        name        = "eclwatch"
        application = "eclwatch"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          port        = 8888
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "eclwatch", var.namespace.name, local.domain) } : {})
        }
        egress      = var.egress.esp_engine
        corsAllowed = var.corsallowed_enable == true ? local.corsAllowed : []
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
        egress = var.egress.esp_engine
      }, local.esp_ldap_config),
      merge({
        name        = "eclqueries"
        application = "eclqueries"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "eclqueries", var.namespace.name, local.domain) } : {})
        }
        egress = var.egress.esp_engine
      }, local.esp_ldap_config),
      merge({
        name        = "esdl-sandbox"
        application = "esdl-sandbox"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "esdl-sandbox", var.namespace.name, local.domain) } : {})
        }
        egress = var.egress.esp_engine
      }, local.esp_ldap_config),
      merge({
        name        = "sql2ecl"
        application = "sql2ecl"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          servicePort = 443
          visibility  = "local"
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "lnrs.io/zone-type"                                       = "public"
          }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "sql2ecl", var.namespace.name, local.domain) } : {})
        }
        egress = var.egress.esp_engine
      }, local.esp_ldap_config)
    ]

    roxie = local.roxie_config

    thor = local.thor_config

    sasha = var.sasha_config


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
      storage    = var.secrets.remote_cert_secret
      system     = merge(local.vault_secrets, {})
      esp        = {}
    }

    vaults = local.vault_enabled ? {
      git     = local.vault_git_config
      ecl     = local.vault_ecl_config
      eclUser = local.vault_ecluser_config
      esp     = local.vault_esp_config
    } : null

  }

}
