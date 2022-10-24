variable "admin_services_node_selector" {
  description = "Node selector for admin services pods."
  type        = map(map(string))
  default     = {}

  validation {
    condition = length([for service in keys(var.admin_services_node_selector) :
    service if !contains(["all", "dali", "esp", "eclagent", "eclccserver"], service)]) == 0
    error_message = "The keys must be one of \"all\", \"dali\", \"esp\", \"eclagent\" or \"eclccserver\"."
  }
}

variable "admin_services_storage_account_settings" {
  description = "Settings for admin services storage account."
  type = object({
    authorized_ip_ranges                 = map(string)
    delete_protection                    = bool
    replication_type                     = string
    subnet_ids                           = map(string)
    blob_soft_delete_retention_days      = optional(number)
    container_soft_delete_retention_days = optional(number)
    file_share_retention_days            = optional(number)
  })
  default = {
    authorized_ip_ranges                 = {}
    delete_protection                    = false
    replication_type                     = "ZRS"
    subnet_ids                           = {}
    blob_soft_delete_retention_days      = 7
    container_soft_delete_retention_days = 7
    file_share_retention_days            = 7
  }
}

variable "admin_services_storage" {
  description = "PV sizes for admin service planes in gigabytes (storage billed only as consumed)."
  type = object({
    dali = object({
      size = number
      type = string
    })
    debug = object({
      size = number
      type = string
    })
    dll = object({
      size = number
      type = string
    })
    lz = object({
      size = number
      type = string
    })
    sasha = object({
      size = number
      type = string
    })
  })
  default = {
    dali = {
      size = 100
      type = "azurefiles"
    }
    debug = {
      size = 100
      type = "blobnfs"
    }
    dll = {
      size = 100
      type = "blobnfs"
    }
    lz = {
      size = 100
      type = "blobnfs"
    }
    sasha = {
      size = 100
      type = "blobnfs"
    }
  }

  validation {
    condition     = length([for k, v in var.admin_services_storage : v.type if !contains(["azurefiles", "blobnfs"], v.type)]) == 0
    error_message = "The type must be either \"azurefiles\" or \"blobnfs\"."
  }

  validation {
    condition     = length([for k, v in var.admin_services_storage : v.size if v.type == "azurefiles" && v.size < 100]) == 0
    error_message = "Size must be at least 100 for \"azurefiles\" type."
  }
}


variable "data_storage_config" {
  description = "Data plane config for HPCC."
  type = object({
    internal = object({
      blob_nfs = object({
        data_plane_count = number
        storage_account_settings = object({
          authorized_ip_ranges                 = map(string)
          delete_protection                    = bool
          replication_type                     = string
          subnet_ids                           = map(string)
          blob_soft_delete_retention_days      = optional(number)
          container_soft_delete_retention_days = optional(number)
        })
      })
      hpc_cache = object({
        cache_update_frequency = string
        dns = object({
          zone_name                = string
          zone_resource_group_name = string
        })
        resource_provider_object_id = string
        size                        = string
        storage_account_data_planes = list(object({
          container_id         = string
          container_name       = string
          id                   = number
          resource_group_name  = string
          storage_account_id   = string
          storage_account_name = string
        }))
        subnet_id = string
      })
    })
    external = object({
      blob_nfs = list(object({
        container_id         = string
        container_name       = string
        id                   = string
        resource_group_name  = string
        storage_account_id   = string
        storage_account_name = string
      }))
      hpc_cache = list(object({
        id     = string
        path   = string
        server = string
      }))
      hpcc = list(object({
        name = string
        planes = list(object({
          local  = string
          remote = string
        }))
        service = string
      }))
    })
  })
  default = {
    internal = {
      blob_nfs = {
        data_plane_count = 1
        storage_account_settings = {
          authorized_ip_ranges                 = {}
          delete_protection                    = false
          replication_type                     = "ZRS"
          subnet_ids                           = {}
          blob_soft_delete_retention_days      = 7
          container_soft_delete_retention_days = 7
        }
      }
      hpc_cache = null
    }
    external = null
  }

  validation {
    condition = (var.data_storage_config.internal == null ? true :
      var.data_storage_config.internal.hpc_cache == null ? true :
    contains(["never", "30s", "3h"], var.data_storage_config.internal.hpc_cache.cache_update_frequency))
    error_message = "HPC Cache update frequency must be \"never\", \"30s\" or \"3h\"."
  }
}



variable "remote_storage_plane" {
  description = "Input for attaching remote storage plane"
  type = map(object({
    dfs_service_name = string
    target_storage_accounts = map(object({
      name   = string
      prefix = string
    }))
  }))
  default = null
}
variable "onprem_lz_settings" {
  description = "Input for allowing OnPrem LZ."
  type = map(object({
    prefix = string
    hosts  = list(string)
  }))
  default = {}
}

variable "environment_variables" {
  description = "Adds default environment variables for all components."
  type        = map(string)
  default     = {}
}

variable "enable_node_tuning" {
  description = "Enable node tuning daemonset (only needed once per AKS cluster)."
  type        = bool
  default     = true
}

variable "helm_chart_overrides" {
  description = "Helm chart values, in yaml format, to be merged last."
  type        = string
  default     = ""
}

variable "helm_chart_timeout" {
  description = "Helm timeout for hpcc chart."
  type        = number
  default     = 600
}

variable "helm_chart_version" {
  description = "Version of the HPCC Helm Chart to use."
  type        = string
  default     = "8.6.20"
}

variable "hpcc_container" {
  description = "HPCC container information (if version is set to null helm chart version is used)."
  type = object({
    image_name = string
    image_root = string
    version    = string
  })
}

variable "hpcc_container_registry_auth" {
  description = "Registry authentication for HPCC container."
  type = object({
    password = string
    username = string
  })
  default   = null
  sensitive = true
}

variable "install_blob_csi_driver" {
  description = "Install blob-csi-drivers on the cluster."
  type        = bool
  default     = true
}

variable "ldap_config" {
  description = "LDAP settings for dali and esp services."
  type = object({
    dali = object({
      adminGroupName      = string
      filesBasedn         = string
      groupsBasedn        = string
      hpcc_admin_password = string
      hpcc_admin_username = string
      ldap_admin_password = string
      ldap_admin_username = string
      ldapAdminVaultId    = string
      resourcesBasedn     = string
      sudoersBasedn       = string
      systemBasedn        = string
      usersBasedn         = string
      workunitsBasedn     = string
    })
    esp = object({
      adminGroupName      = string
      filesBasedn         = string
      groupsBasedn        = string
      ldap_admin_password = string
      ldap_admin_username = string
      ldapAdminVaultId    = string
      resourcesBasedn     = string
      sudoersBasedn       = string
      systemBasedn        = string
      usersBasedn         = string
      workunitsBasedn     = string
    })
    ldap_server = string
  })
  default   = null
  sensitive = true
}

variable "ldap_tunables" {
  description = "Tunable settings for LDAP."
  type = object({
    cacheTimeout                  = number
    checkScopeScans               = bool
    ldapTimeoutSecs               = number
    maxConnections                = number
    passwordExpirationWarningDays = number
    sharedCache                   = bool
  })
  default = {
    cacheTimeout                  = 5
    checkScopeScans               = false
    ldapTimeoutSecs               = 131
    maxConnections                = 10
    passwordExpirationWarningDays = 10
    sharedCache                   = true
  }
}

variable "location" {
  description = "Azure region in which to create resources."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where resources will be created."
  type = object({
    name   = string
    labels = map(string)
  })
  default = {
    name = "hpcc"
    labels = {
      name = "hpcc"
    }
  }
}

variable "node_tuning_containers" {
  description = "URIs for containers to be used by node tuning submodule."
  type = object({
    busybox = string
    debian  = string
  })
  default = null
}

variable "environment" {
  description = "Environment HPCC is being deployed to."
  type        = string
  default     = "dev"
}

variable "productname" {
  description = "Environment HPCC is being deployed to."
  type        = string
}

variable "node_tuning_container_registry_auth" {
  description = "Registry authentication for node tuning containers."
  type = object({
    password = string
    username = string
  })
  default   = null
  sensitive = true
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources."
  type        = string
}

variable "roxie_config" {
  description = "Configuration for Roxie(s)."
  type = list(object({
    disabled                       = bool
    name                           = string
    nodeSelector                   = map(string)
    numChannels                    = number
    prefix                         = string
    replicas                       = number
    serverReplicas                 = number
    acePoolSize                    = number
    actResetLogPeriod              = number
    affinity                       = number
    allFilesDynamic                = bool
    blindLogging                   = bool
    blobCacheMem                   = number
    callbackRetries                = number
    callbackTimeout                = number
    checkCompleted                 = bool
    checkPrimaries                 = bool
    checkFileDate                  = bool
    clusterWidth                   = number
    copyResources                  = bool
    coresPerQuery                  = number
    crcResources                   = bool
    dafilesrvLookupTimeout         = number
    debugPermitted                 = bool
    defaultConcatPreload           = number
    defaultFetchPreload            = number
    defaultFullKeyedJoinPreload    = number
    defaultHighPriorityTimeLimit   = number
    defaultHighPriorityTimeWarning = number
    defaultKeyedJoinPreload        = number
    defaultLowPriorityTimeLimit    = number
    defaultLowPriorityTimeWarning  = number
    defaultMemoryLimit             = number
    defaultParallelJoinPreload     = number
    defaultPrefetchProjectPreload  = number
    defaultSLAPriorityTimeLimit    = number
    defaultSLAPriorityTimeWarning  = number
    defaultStripLeadingWhitespace  = bool
    diskReadBufferSize             = number
    doIbytiDelay                   = bool
    enableHeartBeat                = bool
    enableKeyDiff                  = bool
    enableSysLog                   = bool
    fastLaneQueue                  = bool
    fieldTranslationEnabled        = string
    flushJHtreeCacheOnOOM          = bool
    forceStdLog                    = bool
    highTimeout                    = number
    ignoreMissingFiles             = bool
    indexReadChunkSize             = number
    initIbytiDelay                 = number
    jumboFrames                    = bool
    lazyOpen                       = bool
    leafCacheMem                   = number
    linuxYield                     = bool
    localFilesExpire               = number
    localSlave                     = bool
    logFullQueries                 = bool
    logQueueDrop                   = number
    logQueueLen                    = number
    lowTimeout                     = number
    maxBlockSize                   = number
    maxHttpConnectionRequests      = number
    maxLocalFilesOpen              = number
    maxLockAttempts                = number
    maxRemoteFilesOpen             = number
    memTraceLevel                  = number
    memTraceSizeLimit              = number
    memoryStatsInterval            = number
    minFreeDiskSpace               = number
    minIbytiDelay                  = number
    minLocalFilesOpen              = number
    minRemoteFilesOpen             = number
    miscDebugTraceLevel            = number
    monitorDaliFileServer          = bool
    nodeCacheMem                   = number
    nodeCachePreload               = bool
    parallelAggregate              = number
    parallelLoadQueries            = number
    perChannelFlowLimit            = number
    pingInterval                   = number
    preabortIndexReadsThreshold    = number
    preabortKeyedJoinsThreshold    = number
    preloadOnceData                = bool
    prestartSlaveThreads           = bool
    remoteFilesExpire              = number
    roxieMulticastEnabled          = bool
    serverSideCacheSize            = number
    serverThreads                  = number
    simpleLocalKeyedJoins          = bool
    sinkMode                       = string
    slaTimeout                     = number
    slaveConfig                    = string
    slaveThreads                   = number
    soapTraceLevel                 = number
    socketCheckInterval            = number
    statsExpiryTime                = number
    systemMonitorInterval          = number
    traceLevel                     = number
    traceRemoteFiles               = bool
    totalMemoryLimit               = string
    trapTooManyActiveQueries       = bool
    udpAdjustThreadPriorities      = bool
    udpFlowAckTimeout              = number
    udpFlowSocketsSize             = number
    udpInlineCollation             = bool
    udpInlineCollationPacketLimit  = number
    udpLocalWriteSocketSize        = number
    udpMaxPermitDeadTimeouts       = number
    udpMaxRetryTimedoutReqs        = number
    udpMaxSlotsPerClient           = number
    udpMulticastBufferSize         = number
    udpOutQsPriority               = number
    udpQueueSize                   = number
    udpRecvFlowTimeout             = number
    udpRequestToSendAckTimeout     = number
    udpResendTimeout               = number
    udpRequestToSendTimeout        = number
    udpResendEnabled               = bool
    udpRetryBusySenders            = number
    udpSendCompletedInData         = bool
    udpSendQueueSize               = number
    udpSnifferEnabled              = bool
    udpTraceLevel                  = number
    useAeron                       = bool
    useDynamicServers              = bool
    useHardLink                    = bool
    useLogQueue                    = bool
    useMemoryMappedIndexes         = bool
    useTreeCopy                    = bool
    services = list(object({
      name        = string
      servicePort = number
      listenQueue = number
      numThreads  = number
      visibility  = string
    }))
    topoServer = object({
      replicas = number
    })
    channelResources = object({
      cpu    = string
      memory = string
    })
  }))
  default = [
    {
      disabled                       = true
      name                           = "roxie"
      nodeSelector                   = {}
      numChannels                    = 2
      prefix                         = "roxie"
      replicas                       = 2
      serverReplicas                 = 0
      acePoolSize                    = 6
      actResetLogPeriod              = 0
      affinity                       = 0
      allFilesDynamic                = false
      blindLogging                   = false
      blobCacheMem                   = 0
      callbackRetries                = 3
      callbackTimeout                = 500
      checkCompleted                 = true
      checkFileDate                  = false
      checkPrimaries                 = true
      clusterWidth                   = 1
      copyResources                  = true
      coresPerQuery                  = 0
      crcResources                   = false
      dafilesrvLookupTimeout         = 10000
      debugPermitted                 = true
      defaultConcatPreload           = 0
      defaultFetchPreload            = 0
      defaultFullKeyedJoinPreload    = 0
      defaultHighPriorityTimeLimit   = 0
      defaultHighPriorityTimeWarning = 30000
      defaultKeyedJoinPreload        = 0
      defaultLowPriorityTimeLimit    = 0
      defaultLowPriorityTimeWarning  = 90000
      defaultMemoryLimit             = 1073741824
      defaultParallelJoinPreload     = 0
      defaultPrefetchProjectPreload  = 10
      defaultSLAPriorityTimeLimit    = 0
      defaultSLAPriorityTimeWarning  = 30000
      defaultStripLeadingWhitespace  = false
      diskReadBufferSize             = 65536
      doIbytiDelay                   = true
      enableHeartBeat                = false
      enableKeyDiff                  = false
      enableSysLog                   = false
      fastLaneQueue                  = true
      fieldTranslationEnabled        = "payload"
      flushJHtreeCacheOnOOM          = true
      forceStdLog                    = false
      highTimeout                    = 2000
      ignoreMissingFiles             = false
      indexReadChunkSize             = 60000
      initIbytiDelay                 = 10
      jumboFrames                    = false
      lazyOpen                       = true
      leafCacheMem                   = 500
      linuxYield                     = false
      localFilesExpire               = 1
      localSlave                     = false
      logFullQueries                 = false
      logQueueDrop                   = 32
      logQueueLen                    = 512
      lowTimeout                     = 10000
      maxBlockSize                   = 1000000000
      maxHttpConnectionRequests      = 1
      maxLocalFilesOpen              = 4000
      maxLockAttempts                = 5
      maxRemoteFilesOpen             = 100
      memTraceLevel                  = 1
      memTraceSizeLimit              = 0
      memoryStatsInterval            = 60
      minFreeDiskSpace               = 6442450944
      minIbytiDelay                  = 2
      minLocalFilesOpen              = 2000
      minRemoteFilesOpen             = 50
      miscDebugTraceLevel            = 0
      monitorDaliFileServer          = false
      nodeCacheMem                   = 1000
      nodeCachePreload               = false
      parallelAggregate              = 0
      parallelLoadQueries            = 1
      perChannelFlowLimit            = 50
      pingInterval                   = 0
      preabortIndexReadsThreshold    = 100
      preabortKeyedJoinsThreshold    = 100
      preloadOnceData                = true
      prestartSlaveThreads           = false
      remoteFilesExpire              = 3600
      roxieMulticastEnabled          = false
      serverSideCacheSize            = 0
      serverThreads                  = 100
      simpleLocalKeyedJoins          = true
      sinkMode                       = "sequential"
      slaTimeout                     = 2000
      slaveConfig                    = "simple"
      slaveThreads                   = 30
      soapTraceLevel                 = 1
      socketCheckInterval            = 5000
      statsExpiryTime                = 3600
      systemMonitorInterval          = 60000
      totalMemoryLimit               = "5368709120"
      traceLevel                     = 1
      traceRemoteFiles               = false
      trapTooManyActiveQueries       = true
      udpAdjustThreadPriorities      = true
      udpFlowAckTimeout              = 10
      udpFlowSocketsSize             = 33554432
      udpInlineCollation             = true
      udpInlineCollationPacketLimit  = 50
      udpLocalWriteSocketSize        = 16777216
      udpMaxPermitDeadTimeouts       = 100
      udpMaxRetryTimedoutReqs        = 10
      udpMaxSlotsPerClient           = 100
      udpMulticastBufferSize         = 33554432
      udpOutQsPriority               = 5
      udpQueueSize                   = 1000
      udpRecvFlowTimeout             = 2000
      udpRequestToSendAckTimeout     = 500
      udpResendTimeout               = 100
      udpRequestToSendTimeout        = 2000
      udpResendEnabled               = true
      udpRetryBusySenders            = 0
      udpSendCompletedInData         = false
      udpSendQueueSize               = 500
      udpSnifferEnabled              = false
      udpTraceLevel                  = 0
      useAeron                       = false
      useDynamicServers              = false
      useHardLink                    = false
      useLogQueue                    = true
      useMemoryMappedIndexes         = false
      useRemoteResources             = false
      useTreeCopy                    = false
      services = [
        {
          name        = "roxie"
          servicePort = 9876
          listenQueue = 200
          numThreads  = 30
          visibility  = "local"
        }
      ]
      topoServer = {
        replicas = 1
      }
      channelResources = {
        cpu    = "1"
        memory = "4G"
      }
    }
  ]
}

variable "spill_volume_size" {
  description = "Size of spill volume to be created (in GB)."
  type        = number
  default     = null
}

variable "thor_config" {
  description = "Configuration for Thor(s)."
  type = list(object({
    disabled = bool
    eclAgentResources = object({
      cpu    = string
      memory = string
    })
    keepJobs = string
    managerResources = object({
      cpu    = string
      memory = string
    })
    maxGraphs        = number
    maxJobs          = number
    name             = string
    nodeSelector     = map(string)
    numWorkers       = number
    numWorkersPerPod = number
    prefix           = string
    workerMemory = object({
      query      = string
      thirdParty = string
    })
    workerResources = object({
      cpu    = string
      memory = string
    })
  }))
  default = [{
    disabled = true
    eclAgentResources = {
      cpu    = 1
      memory = "2G"
    }
    managerResources = {
      cpu    = 1
      memory = "2G"
    }
    keepJobs         = "none"
    maxGraphs        = 2
    maxJobs          = 4
    name             = "thor"
    nodeSelector     = {}
    numWorkers       = 2
    numWorkersPerPod = 1
    prefix           = "thor"
    workerMemory = {
      query      = "3G"
      thirdParty = "500M"
    }
    workerResources = {
      cpu    = 3
      memory = "4G"
    }
  }]
}

variable "tags" {
  description = "Tags to be applied to Azure resources."
  type        = map(string)
  default     = {}
}

variable "disable_directio" {
  description = "Set false to enable directio, true to disable. Defaults to disabled."
  type        = bool
  default     = true
}

variable "disable_rowservice" {
  description = "Set false to enable row_service, true to disable. Defaults to disabled. Requires Certificates Enabled as of now to setup row service."
  type        = bool
  default     = true
}

variable "eclccserver_settings" {
  description = "Set cpu and memory values of the eclccserver. Toggle use_child_process to true to enable eclccserver child processes."
  type = object({
    use_child_process = bool
    cpu               = string
    memory            = string
  })
  default = {
    use_child_process = false
    cpu               = "1"
    memory            = "4G"
  }
}

variable "dali_settings" {
  description = "dali settings"
  type = object({
    coalescer = object({
      interval     = number
      at           = string
      minDeltaSize = number
      resources = object({
        cpu    = string
        memory = string
      })
    })
    resources = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    coalescer = {
      interval     = 24
      at           = "* * * * *"
      minDeltaSize = 50000
      resources = {
        cpu    = "1"
        memory = "4G"
      }
    }
    resources = {
      cpu    = "2"
      memory = "8G"
    }
  }
}

variable "dfuserver_settings" {
  description = "DFUServer settings"
  type = object({
    maxJobs = number
    resources = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    maxJobs = 3
    resources = {
      cpu    = "1"
      memory = "2G"
    }
  }
}


variable "spray_service_settings" {
  description = "spray services settings"
  type = object({
    replicas = number
  })
  default = {
    replicas = 3
  }
}

###sasha config

variable "sasha_config" {
  description = "Configuration for Sasha."
  type = object({
    disabled = bool
    wu-archiver = object({
      disabled = bool
      service = object({
        servicePort = number
      })
      plane           = string
      interval        = number
      limit           = number
      cutoff          = number
      backup          = number
      at              = string
      throttle        = number
      retryinterval   = number
      keepResultFiles = bool
    })

    dfuwu-archiver = object({
      disabled = bool
      service = object({
        servicePort = number
      })
      plane    = string
      interval = number
      limit    = number
      cutoff   = number
      at       = string
      throttle = number
    })

    dfurecovery-archiver = object({
      disabled = bool
      interval = number
      limit    = number
      cutoff   = number
      at       = string
    })

    file-expiry = object({
      disabled             = bool
      interval             = number
      at                   = string
      persistExpiryDefault = number
      expiryDefault        = number
      user                 = string
    })
  })
  default = {
    disabled = false
    wu-archiver = {
      disabled = false
      service = {
        servicePort = 8877
      }
      plane           = "sasha"
      interval        = 6
      limit           = 400
      cutoff          = 3
      backup          = 0
      at              = "* * * * *"
      throttle        = 0
      retryinterval   = 6
      keepResultFiles = false
    }

    dfuwu-archiver = {
      disabled = false
      service = {
        servicePort = 8877
      }
      plane    = "sasha"
      interval = 24
      limit    = 100
      cutoff   = 14
      at       = "* * * * *"
      throttle = 0
    }

    dfurecovery-archiver = {
      disabled = false
      interval = 12
      limit    = 20
      cutoff   = 4
      at       = "* * * * *"
    }

    file-expiry = {
      disabled             = false
      interval             = 1
      at                   = "* * * * *"
      persistExpiryDefault = 7
      expiryDefault        = 4
      user                 = "sasha"
    }
  }
}

variable "internal_domain" {
  description = "DNS Domain name"
  type        = string
}

variable "cluster_name" {
  description = "The name of aks cluster."
  type        = string
}

variable "esp_remoteclients" {
  description = "name of the remote client cert to be installed"
  type        = list(map(string))
  default = [
    {
      name = "insuranceprod"
    }
  ]
}

variable "placements" {
  description = "maxskew topologyspreadconstraints placements value for hppc"
  type = object({
    spray-service = object({
      maxskew = number
    })

    eclwatch = object({
      maxskew = number
    })

    eclservices = object({
      maxskew = number
    })

    eclqueries = object({
      maxskew = number
    })

    dfs = object({
      maxskew = number
    })

    direct-access = object({
      maxskew = number
    })

    thorworker = object({
      maxskew = number
    })

    roxie-agent = object({
      maxskew = number
    })
  })

  default = {
    spray-service = {
      maxskew = 1
    }

    eclwatch = {
      maxskew = 1
    }

    eclservices = {
      maxskew = 1
    }

    spray-service = {
      maxskew = 1
    }

    eclqueries = {
      maxskew = 1
    }

    dfs = {
      maxskew = 1
    }

    direct-access = {
      maxskew = 1
    }

    thorworker = {
      maxskew = 1
    }

    roxie-agent = {
      maxskew = 1
    }
  }
}
