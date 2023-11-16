locals {

  create_hpcc_registry_auth_secret = var.hpcc_container_registry_auth != null ? true : false

  admin_services_storage = local.external_storage_config_enabled ? merge(
    {
      for plane in var.external_storage_config :
      plane.category => {
        size = plane.size,
        type = plane.storage_type
      } if plane.category != "data"
  }) : var.admin_services_storage

  azurefiles_admin_storage_enabled = contains([for storage in local.admin_services_storage : storage.type], "azurefiles")
  blobnfs_admin_storage_enabled    = contains([for storage in local.admin_services_storage : storage.type], "blobnfs")

  internal_data_config            = var.data_storage_config.internal == null ? false : true
  external_data_config            = var.data_storage_config.external == null ? false : true
  external_storage_config_enabled = (var.external_storage_config != null) && (var.internal_storage_enabled == false) ? true : false

  create_data_storage = (local.internal_data_config ? (var.data_storage_config.internal.blob_nfs == null ? false : true) : false)
  # create_data_storage = var.external_storage_config == null ? true : false

  external_data_storage = (local.external_data_config ? (var.data_storage_config.external.blob_nfs == null ? false : true) : false)
  external_hpcc_data    = (local.external_data_config ? (var.data_storage_config.external.hpcc == null ? false : true) : false)

  acr_default = {
    busybox = "busybox:latest"
    debian  = "debian:bullseye-slim"
  }

  external_dns_zone_enabled      = var.internal_domain != null
  internal_load_balancer_enabled = local.external_dns_zone_enabled ? false : true                                             // For ECLWatch service
  servicePort                    = local.external_dns_zone_enabled ? local.certificates.enabled == false ? 8010 : 18010 : 443 // For ECLWatch service
  visibility                     = local.external_dns_zone_enabled ? "global" : "local"                                       // For ECLWatch service

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
        name   = "zerossl"
        kind   = "ClusterIssuer"
        domain = var.internal_domain
        spec   = null
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

  domain           = coalesce(var.internal_domain, format("us-%s.%s.azure.lnrsg.io", var.productname, var.environment))
  account_code     = split(".", local.domain)[0]
  aks_trimmed_name = trimprefix(var.cluster_name, "${local.account_code}-")


  azure_files_pv_protocol = var.environment == "dev" ? "nfs" : null
  storage_config = {
    blob_nfs = (local.create_data_storage ? module.data_storage.0.data_planes : (
      local.external_data_storage ? var.data_storage_config.external.blob_nfs : null)
    )
    hpcc = local.external_hpcc_data ? var.data_storage_config.external.hpcc : []
  }

  data_storage_planes = [
    for v in var.external_storage_config : v if v.plane_name == "data"
  ]

  blob_nfs_data_enabled = local.storage_config.blob_nfs != null ? true : false
  remote_data_enabled   = local.storage_config.hpcc == null ? false : true
  spill_space_enabled   = length(var.spill_volumes) > 0 ? true : false

  blob_nfs_data_storage = local.blob_nfs_data_enabled ? { for plane in local.storage_config.blob_nfs :
    length(local.storage_config.blob_nfs) == 1 ? "data" : "data-${plane.id}" => {
      category        = "data"
      container_name  = plane.container_name
      id              = plane.id
      path            = "hpcc-data"
      resource_group  = plane.resource_group_name
      storage_account = plane.storage_account_name
      size            = (var.storage_data_gb != null) ? (var.storage_data_gb < 1000000) ? "1Pi" : "${ceil(var.storage_data_gb / 1000000)}Pi" : "5Pi"
    }
    } : local.external_storage_config_enabled ? { for v in var.external_storage_config : "data-${tostring(index(local.data_storage_planes, v) + 1)}" => {
      category        = "data"
      container_name  = v.container_name
      id              = tostring(index(local.data_storage_planes, v) + 1)
      path            = "hpcc-data"
      resource_group  = v.resource_group
      storage_account = v.storage_account
      size            = "${v.size}Pi"
    } if v.plane_name == "data"
  } : {}

  services_storage_config = local.external_storage_config_enabled ? [for v in var.external_storage_config :
    {
      category        = v.category
      container_name  = v.container_name
      path            = v.path
      plane_name      = v.plane_name
      size            = "${v.size}G"
      storage_type    = v.storage_type
      resource_group  = v.resource_group
      storage_account = v.storage_account
    } if v.plane_name != "data"
    ] : [
    {
      category        = "dali"
      container_name  = "hpcc-dali"
      path            = "dalistorage"
      plane_name      = "dali"
      size            = "${local.admin_services_storage.dali.size}G"
      storage_type    = local.admin_services_storage.dali.type
      resource_group  = var.resource_group_name
      storage_account = local.admin_services_storage.dali.type == "azurefiles" ? azurerm_storage_account.azurefiles_admin_services.0.name : azurerm_storage_account.blob_nfs_admin_services.0.name
    },
    {
      category        = "debug"
      container_name  = "hpcc-debug"
      path            = "debug"
      plane_name      = "debug"
      size            = "${local.admin_services_storage.debug.size}G"
      storage_type    = local.admin_services_storage.debug.type
      resource_group  = var.resource_group_name
      storage_account = local.admin_services_storage.debug.type == "azurefiles" ? azurerm_storage_account.azurefiles_admin_services.0.name : azurerm_storage_account.blob_nfs_admin_services.0.name
    },
    {
      category        = "dll"
      container_name  = "hpcc-dll"
      path            = "queries"
      plane_name      = "dll"
      size            = "${local.admin_services_storage.dll.size}G"
      storage_type    = local.admin_services_storage.dll.type
      resource_group  = var.resource_group_name
      storage_account = local.admin_services_storage.dll.type == "azurefiles" ? azurerm_storage_account.azurefiles_admin_services.0.name : azurerm_storage_account.blob_nfs_admin_services.0.name
    },
    {
      category        = "lz"
      container_name  = "hpcc-mydropzone"
      path            = "mydropzone"
      plane_name      = "mydropzone"
      size            = "${local.admin_services_storage.lz.size}G"
      storage_type    = local.admin_services_storage.lz.type
      resource_group  = var.resource_group_name
      storage_account = local.admin_services_storage.lz.type == "azurefiles" ? azurerm_storage_account.azurefiles_admin_services.0.name : azurerm_storage_account.blob_nfs_admin_services.0.name
    },
    {
      category        = "sasha"
      container_name  = "hpcc-sasha"
      path            = "sashastorage"
      plane_name      = "sasha"
      size            = "${local.admin_services_storage.sasha.size}G"
      storage_type    = local.admin_services_storage.sasha.type
      resource_group  = var.resource_group_name
      storage_account = local.admin_services_storage.sasha.type == "azurefiles" ? azurerm_storage_account.azurefiles_admin_services.0.name : azurerm_storage_account.blob_nfs_admin_services.0.name
    }
  ]

  azurefiles_services_storage = {
    for config in local.services_storage_config :
    config.plane_name => {
      category        = config.category
      container_name  = config.container_name
      path            = config.path
      resource_group  = config.resource_group
      size            = config.size
      storage_account = config.storage_account
      protocol        = local.azure_files_pv_protocol
    } if config.storage_type == "azurefiles"
  }

  blob_nfs_services_storage = {
    for config in local.services_storage_config :
    config.plane_name => {
      category        = config.category
      container_name  = config.container_name
      path            = config.path
      resource_group  = config.resource_group
      size            = config.size
      storage_account = config.storage_account
    } if config.storage_type == "blobnfs"
  }

  eclccserver_settings = [for k, v in var.eclccserver_settings : {
    name                  = k
    replicas              = v.replicas
    useChildProcesses     = v.useChildProcesses
    childProcessTimeLimit = v.childProcessTimeLimit
    maxActive             = v.maxActive
    #eclSecurity           = v.eclSecurity # add this line when enable_code_security is true.
    resources          = v.resources
    egress             = v.egress
    listen             = v.listen_queue
    gitUsername        = v.gitUsername
    defaultRepo        = v.defaultRepo
    defaultRepoVersion = v.defaultRepoVersion
    cost               = v.cost
    options            = v.legacySyntax != false ? concat([{ name = "eclcc-legacyimport", value = 1 }, { name = "eclcc-legacywhen", value = 1 }], v.options) : v.options
  }]

  ldap_defaults = {
    serverType     = "ActiveDirectory"
    description    = "LDAP server process"
    ldapProtocol   = "ldaps"
    ldapPort       = 389
    ldapSecurePort = 636
  }

  # ESP Remote Clients 

  esp_remoteclients = length(var.esp_remoteclients) > 0 ? [for k, v in var.esp_remoteclients : {
    name = v.name
    secretTemplate = {
      labels = v.labels
    }
  }] : []

  # Remote Plane Secrets 

  remote_plane_secrets = local.remote_storage_enabled ? { for k, v in var.remote_storage_plane : v.dfs_secret_name => v.dfs_secret_name
  } : null

  # Vault Secrets Section
  vault_enabled = var.vault_config == null && var.vault_config != null ? false : true

  all_vault_secrets = local.vault_enabled ? values(merge(var.vault_secrets.ecluser_approle_secret, var.vault_secrets.ecl_approle_secret, var.vault_secrets.git_approle_secret, var.vault_secrets.esp_approle_secret)) : []

  vault_secrets = local.vault_enabled ? { for k in local.all_vault_secrets : k.secret_name => k.secret_name

  } : null


  vault_git_config = var.vault_config != null ? var.vault_config.git != null ? [for k, v in var.vault_config.git : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null : null

  vault_ecl_config = var.vault_config != null ? var.vault_config.ecl != null ? [for k, v in var.vault_config.ecl : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null : null

  vault_ecluser_config = var.vault_config != null ? var.vault_config.ecluser != null ? [for k, v in var.vault_config.ecluser : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null : null

  vault_esp_config = var.vault_config != null ? var.vault_config.esp != null ? [for k, v in var.vault_config.esp : {
    name          = v.name
    url           = v.url
    kind          = v.kind
    namespace     = v.vault_namespace
    appRoleId     = v.role_id
    appRoleSecret = v.secret_name
  }] : null : null

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
    cost              = v.cost
    spillPlane        = v.spillPlane
  }]

  roxie_config_excludes = ["nodeSelector"]

  # Appends namespace to roxie name and service names

  roxie_name_update = [for roxie in var.roxie_config :
    merge(roxie, {
      name   = format("%s-%s", roxie.name, var.namespace.name)
      prefix = format("%s-%s", roxie.prefix, var.namespace.name)
      services = [for service in roxie.services :
        merge(service, {
          name = format("%s-%s", service.name, var.namespace.name)
        })
      ]
    })
  ]


  roxie_config = [for roxie in local.roxie_name_update :
    { for k, v in roxie : k => v if !contains(local.roxie_config_excludes, k) }
  ]

  # Add External DNS for Roxie Services
  roxie_config_external_dns_annotations = [for roxie in local.roxie_config :
    merge(roxie, {
      services = [for service in roxie.services :
        merge(service, {
          annotations = merge(
            service.annotations,
            local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s.%s", roxie.name, local.domain) } : {},
            {
              "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
              "lnrs.io/zone-type"                                       = "public"
            }
          )
        })
      ]
    })
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
    { pods = [format("target:%s-%s", roxie.name, var.namespace.name)], placement = { nodeSelector = roxie.nodeSelector } } if length(roxie.nodeSelector) > 0
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
        volume_name            = format("%s-remote-pv-hpcc-data-%s", subscription_key, sa_key)
        volume_claim_name      = format("%s-remote-pvc-hpcc-data-%s", subscription_key, sa_key)
      }
    ]
  ]) : []

  remote_storage_helm_values = local.remote_storage_enabled ? { for k, v in var.remote_storage_plane : k => {
    dfs_service_name = v.dfs_service_name
    dfs_secret_name  = v.dfs_secret_name
    numDevices       = length(v.target_storage_accounts)
  } } : null

  onprem_lz_enabled = var.onprem_lz_settings == null ? false : true

  onprem_lz_helm_values = local.onprem_lz_enabled ? [for k, v in var.onprem_lz_settings : {
    category = "lz"
    name     = k
    prefix   = v.prefix
    hosts    = v.hosts
  }] : null

  corsAllowed = length(var.corsAllowed) > 0 ? [for k, v in var.corsAllowed : {
    origin  = v.origin
    headers = v.headers
    methods = v.methods
    }
  ] : []

  global_eclqueries_service = {
    servicePort = 18002
    visibility  = "global"
    loadBalancerSourceRanges = var.hpcc_user_ip_cidr_list
    annotations = merge({
      "service.beta.kubernetes.io/azure-load-balancer-internal" = tostring(local.internal_load_balancer_enabled)
      "lnrs.io/zone-type"                                       = "public"
    }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "eclqueries", var.namespace.name, local.domain) } : {}),
  }

  local_eclqueries_service = {
    servicePort = 443
    visibility  = "local"
    loadBalancerSourceRanges = var.hpcc_user_ip_cidr_list
    annotations = merge({
      "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
      "lnrs.io/zone-type"                                       = "public"
    }, local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "eclqueries", var.namespace.name, local.domain) } : {})
  }

  eclqueries_service = var.enable_roxie ? local.global_eclqueries_service : local.local_eclqueries_service

  helm_chart_values0 = {

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
        #version    = var.hpcc_container.version
        version    = var.hpcc_version
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
        perCpu        = var.global_cost.perCpu
        storageAtRest = var.global_cost.storageAtRest
        storageReads  = var.global_cost.storageReads
        storageWrites = var.global_cost.storageWrites
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
          ], local.blob_nfs_data_enabled || local.external_storage_config_enabled ? [
          {
            category   = "data"
            name       = "data"
            numDevices = length(local.blob_nfs_data_storage)
            prefix     = "/var/lib/HPCCSystems/hpcc-data"
            pvc        = "pvc-blob-data"
          }
        ] : [],
        local.spill_space_enabled ? [for k, v in var.spill_volumes : {
          category         = "spill"
          name             = v.name
          prefix           = v.prefix
          pvc              = "${var.namespace.name}-pvc-${v.name}"
          forcePermissions = true
          waitForMount     = true
          }
          ] : [], local.onprem_lz_enabled ? local.onprem_lz_helm_values : [], local.remote_storage_enabled ? [for k, v in local.remote_storage_helm_values :
          {
            category   = "remote"
            prefix     = format("/var/lib/HPCCSystems/%s-data", k)
            name       = format("%s-remote-hpcc-data", k)
            pvc        = format("%s-remote-pvc-hpcc-data", k)
            numDevices = v.numDevices
          }
        ] : []
        ) }, local.remote_storage_enabled ? { remote = [for k, v in local.remote_storage_helm_values : {
          name    = format("%s-data", k)
          service = v.dfs_service_name
          secret  = v.dfs_secret_name
          planes = [
            {
              remote = "data"
              local  = format("%s-remote-hpcc-data", k)
            }
          ]
      }] } : {}, local.external_hpcc_data ? { remote = local.storage_config.hpcc } : {},
    )

    certificates = local.certificates

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
        name           = "mydali"
        auth           = local.auth_mode
        maxStartupTime = var.dali_settings.maxStartupTime
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
        name          = format("dfs-%s", var.namespace.name)
        application   = "dfs"
        remoteClients = local.esp_remoteclients
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
        #name        = format("eclwatch-%s", var.namespace.name)
        name        = var.a_record_name
        application = "eclwatch"
        auth        = local.auth_mode
        replicas    = 1
        service = {
          port        = 8888
          servicePort = local.servicePort
          visibility  = local.visibility
          loadBalancerSourceRanges = var.hpcc_user_ip_cidr_list
          annotations = merge({
            "service.beta.kubernetes.io/azure-load-balancer-internal" = tostring(local.internal_load_balancer_enabled)
            "lnrs.io/zone-type"                                       = "public"
          },
          # tlh 20231115 local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s-%s.%s", "eclwatch", var.namespace.name, local.domain) } : {})
          local.external_dns_zone_enabled ? { "external-dns.alpha.kubernetes.io/hostname" = format("%s.%s", var.a_record_name, local.domain) } : {})
        }
        egress      = var.egress.esp_engine
        corsAllowed = local.corsAllowed
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
        name        = format("eclqueries-%s", var.namespace.name)
        application = "eclqueries"
        auth        = local.auth_mode
        replicas    = 1
        service     = local.eclqueries_service
        egress      = var.egress.esp_engine
      }, local.esp_ldap_config),
      merge({
        name        = format("esdl-sandbox-%s", var.namespace.name)
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
        name        = format("sql2ecl-%s", var.namespace.name)
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

    roxie = local.roxie_config_external_dns_annotations

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
      storage    = merge(local.remote_plane_secrets, {})
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

  #=======================================================================================
  # Adding htpasswd support
  #---------------------------------------------------------------------------------------
  enable_htpasswd = (try(var.authn_htpasswd_filename, "") != "")

  esp0 = local.helm_chart_values0.esp

  esp_with_htpasswd1 = {
    esp = [
      for s in(local.esp0)
      : merge(
        s,
        local.enable_htpasswd && s.service.visibility == "global" ? { auth = "htpasswdSecMgr" } : {},
        local.enable_htpasswd && s.service.visibility == "global" && s.application == "eclwatch" ? yamldecode(file("${path.module}/yaml_files/eclwatch.yaml")) : {},
        local.enable_htpasswd && s.service.visibility == "global" && s.application == "eclqueries" ? yamldecode(file("${path.module}/yaml_files/eclqueries.yaml")) : {},
        local.enable_htpasswd && s.service.visibility == "global" && s.application == "sql2ecl" ? yamldecode(file("${path.module}/yaml_files/sql2ecl.yaml")) : {}
      )
    ]
  }

  # Now go back and fix the htpasswdFile entries
  esp_with_htpasswd2 = {
    esp = [
      for s in(local.esp_with_htpasswd1.esp)
      : merge(
        s,
        s.auth == "htpasswdSecMgr" ? { authNZ = { htpasswdSecMgr = merge(s.authNZ.htpasswdSecMgr, { htpasswdFile = "/var/lib/HPCCSystems/queries/${var.authn_htpasswd_filename}" }) } } : {}
      )
    ]
  }

  #======================================================================================
  # Adding eclSecurity
  eclSecurity = var.enable_code_security ? yamldecode(file("${path.module}/yaml_files/security.yaml")) : {}

  helm_chart_values = merge(local.helm_chart_values0, local.esp_with_htpasswd2, local.eclSecurity)
  #=======================================================================================
}
