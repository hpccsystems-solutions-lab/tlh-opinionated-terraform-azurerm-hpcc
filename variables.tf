variable "hpcc_version" {
  description = "The version of HPCC Systems to install.\nOnly versions in nn.nn.nn format are supported. Default is 'latest'"
  type        = string
  validation {
    condition     = (var.hpcc_version == "latest") || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(-rc\\d{1,3})?$", var.hpcc_version))
    error_message = "Value must be 'latest' OR in nn.nn.nn format and 8.6.0 or higher."
  }
  default = "latest"
}

variable "a_record_name" {
  type        = string
  description = "dns zone eclwatch A record name"
  default     = "eclwatch-default"
}

variable "hpcc_user_ip_cidr_list" {
  description = "OPTIONAL.  List of additional CIDR addresses that can access this HPCC Systems cluster.\nDefault value is '[]' which means no CIDR addresses.\nTo open to the internet, add \"0.0.0.0/0\"."
  type        = list(string)
  default     = []
}

variable "storage_data_gb" {
  type        = number
  description = "REQUIRED.  The amount of storage reserved for data in gigabytes.\nMust be 10 or more.\nIf a storage account is defined (see below) then this value is ignored."
  validation {
    condition     = var.storage_data_gb >= 10
    error_message = "Value must be 10 or more."
  }
}

variable "enable_code_security" {
  description = "REQUIRED.  Enable code security?\nIf true, only signed ECL code will be allowed to create embedded language functions, use PIPE(), etc.\nExample entry: false"
  type        = bool
}

variable "authn_htpasswd_filename" {
  type        = string
  description = "OPTIONAL.  If you would like to use htpasswd to authenticate users to the cluster, enter the filename of the htpasswd file.  This file should be uploaded to the Azure 'dllsshare' file share in order for the HPCC processes to find it.\nA corollary is that persistent storage is enabled.\nAn empty string indicates that htpasswd is not to be used for authentication.\nExample entry: htpasswd.txt"
  default     = ""
}

variable "enable_roxie" {
  description = "REQUIRED.  Enable ROXIE?\nThis will also expose port 8002 on the cluster.\nExample entry: false"
  type        = bool
}

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
    }
    external = null
  }
}

variable "external_storage_config" {
  description = "External services storage config."
  type = list(object({
    category        = string
    container_name  = string
    path            = string
    plane_name      = string
    protocol        = string
    resource_group  = string
    size            = number
    storage_account = string
    storage_type    = string
    prefix_name     = string
  }))

  default = null
}

variable "remote_storage_plane" {
  description = "Input for attaching remote storage plane"
  type = map(object({
    dfs_service_name = string
    dfs_secret_name  = string
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

variable "helm_chart_strings_overrides" {
  description = "Helm chart values as strings, in yaml format, to be merged last."
  type        = list(string)
  default     = []
}

variable "helm_chart_files_overrides" {
  description = "Helm chart values files, in yaml format, to be merged."
  type        = list(string)
  default     = []
}

variable "helm_chart_timeout" {
  description = "Helm timeout for hpcc chart."
  type        = number
  default     = 600
}

#178 - Adding variables  to support keep alive and max connections like expert global setttings

variable "keepalive_settings" {
  description = "Keepalive settings - Global.expert level."
  type = object({
    interval = number
    probes   = number
    time     = number
  })
  default = {
    interval = 75
    probes   = 9
    time     = 200
  }
}

variable "global_max_connections" {
  description = "Value for Global.maxConnections - Global.expert level."
  type        = number
  default     = null
}

variable "global_num_rename_retries" {
  description = "Value for Global.numRenameRetries - Global.expert level."
  type        = number
  default     = null
}

variable "internal_storage_enabled" {
  description = "If true then there will be internal data storage instead of external."
  type        = bool
  default     = true
}

variable "enable_premium_zrs_storage_class" {
  description = "Storage class to use for ZRS file shares."
  type        = bool
  default     = true
}

variable "hpcc_container" {
  description = "HPCC container information (if version is set to null helm chart version is used)."
  type = object({
    image_name           = optional(string, "platform-core")
    image_root           = optional(string, "hpccsystems")
    version              = optional(string, "latest")
    custom_chart_version = optional(string)
    custom_image_version = optional(string)
  })

  default = null
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
      ldapCipherSuite     = string
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
      ldapCipherSuite     = string
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
    name             = string
    labels           = map(string)
    create_namespace = bool
  })
  default = {
    name = "hpcc"
    labels = {
      name = "hpcc"
    }
    create_namespace = true
  }
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
    egress                         = string
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
    useRemoteResources             = bool
    useMemoryMappedIndexes         = bool
    useTreeCopy                    = bool
    services = list(object({
      name        = string
      servicePort = number
      listenQueue = number
      numThreads  = number
      visibility  = string
      annotations = optional(map(string))
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
      egress                         = "engineEgress"
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
          annotations = {}
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

variable "spill_volumes" {
  description = "Map of objects to create Spill Volumes"
  type = map(object({
    name          = string # "Name of spill volume to be created."
    size          = number # "Size of spill volume to be created (in GB)."
    prefix        = string # "Prefix of spill volume to be created."
    host_path     = string # "Host path on spill volume to be created."
    storage_class = string # "Storage class of spill volume to be used."
    access_mode   = string # "Access mode of spill volume to be used."
  }))

  default = {
    "spill" = {
      name          = "spill"
      size          = 300
      prefix        = "/var/lib/HPCCSystems/spill"
      host_path     = "/mnt"
      storage_class = "spill"
      access_mode   = "ReadWriteOnce"
    }
  }
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
    maxGraphs           = number
    maxJobs             = number
    maxGraphStartupTime = number
    name                = string
    nodeSelector        = map(string)
    numWorkers          = number
    numWorkersPerPod    = number
    prefix              = string
    egress              = string
    tolerations_value   = string
    spillPlane          = optional(string, "spill")
    workerMemory = object({
      query      = string
      thirdParty = string
    })
    workerResources = object({
      cpu    = string
      memory = string
    })
    cost = object({
      perCpu = number
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
    keepJobs            = "none"
    maxGraphs           = 2
    maxJobs             = 4
    maxGraphStartupTime = 172800
    name                = "thor"
    nodeSelector        = {}
    numWorkers          = 2
    numWorkersPerPod    = 1
    prefix              = "thor"
    spillPlane          = "spill"
    egress              = "engineEgress"
    tolerations_value   = "thorpool"
    workerMemory = {
      query      = "3G"
      thirdParty = "500M"
    }
    workerResources = {
      cpu    = 3
      memory = "4G"
    }
    cost = {
      perCpu = 1
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
  type = map(object({
    useChildProcesses  = optional(bool, false)
    replicas           = optional(number, 1)
    maxActive          = optional(number, 4)
    egress             = optional(string, "engineEgress")
    gitUsername        = optional(string, "")
    defaultRepo        = optional(string, "")
    defaultRepoVersion = optional(string, "")
    eclSecurity = optional(object({
      datafile = string
      embedded = string
      extern   = string
      pipe     = string
    }))
    resources = optional(object({
      cpu    = string
      memory = string
    }))
    cost = object({
      perCpu = number
    })
    listen_queue          = optional(list(string), [])
    childProcessTimeLimit = optional(number, 10)
    legacySyntax          = optional(bool, false)
    options = optional(list(object({
      name  = string
      value = string
    })))
  }))

  default = {
    "myeclccserver" = {
      useChildProcesses     = false
      maxActive             = 4
      egress                = "engineEgress"
      replicas              = 1
      childProcessTimeLimit = 10
      eclSecurity = {
        datafile = "allow"
        embedded = "allowSigned"
        extern   = "allowSigned"
        pipe     = "allowSigned"
      }
      resources = {
        cpu    = "1"
        memory = "4G"
      }
      legacySyntax = false
      options      = []
      cost = {
        perCpu = 1
      }
  } }
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
    maxStartupTime = number
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
    maxStartupTime = 1200
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
    replicas     = number
    nodeSelector = string
  })
  default = {
    replicas     = 3
    nodeSelector = "servpool" #"spraypool"
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
      # egress          = string
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
      # egress   = string
    })

    dfurecovery-archiver = object({
      disabled = bool
      interval = number
      limit    = number
      cutoff   = number
      at       = string
      # egress   = string
    })

    file-expiry = object({
      disabled             = bool
      interval             = number
      at                   = string
      persistExpiryDefault = number
      expiryDefault        = number
      user                 = string
      # egress               = string
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
      # egress          = "engineEgress"
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
      # egress   = "engineEgress"
    }

    dfurecovery-archiver = {
      disabled = false
      interval = 12
      limit    = 20
      cutoff   = 4
      at       = "* * * * *"
      # egress   = "engineEgress"
    }

    file-expiry = {
      disabled             = false
      interval             = 1
      at                   = "* * * * *"
      persistExpiryDefault = 7
      expiryDefault        = 4
      user                 = "sasha"
      # egress               = "engineEgress"
    }
  }
}

variable "internal_domain" {
  description = "DNS Domain name"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "The name of aks cluster."
  type        = string
}

variable "esp_remoteclients" {
  type = map(object({
    name   = string
    labels = map(string)
  }))

  default = {}
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

variable "global_cost" {
  description = "Global cost settings"
  type = object({
    perCpu        = number
    storageAtRest = number
    storageReads  = number
    storageWrites = number
  })
  default = {
    perCpu        = 3
    storageAtRest = 0.126
    storageReads  = 0.0135
    storageWrites = 0.0038
  }
}

variable "secrets" {
  description = "Secret for egress remote cert."
  type = object({
    remote_cert_secret = map(string)
  })
  default = {
    remote_cert_secret = {}
  }
}


variable "vault_secrets" {
  description = "System Secrets"
  type = object({
    git_approle_secret = map(object({
      secret_name  = optional(string)
      secret_value = optional(string)
    }))
    ecl_approle_secret = map(object({
      secret_name  = optional(string)
      secret_value = optional(string)
    }))
    ecluser_approle_secret = map(object({
      secret_name  = optional(string)
      secret_value = optional(string)
    }))
    esp_approle_secret = map(object({
      secret_name  = optional(string)
      secret_value = optional(string)
    }))
  })
  default = {
    git_approle_secret     = null
    ecl_approle_secret     = null
    ecluser_approle_secret = null
    esp_approle_secret     = null
  }

}



variable "corsAllowed" {
  description = "corsAllowed settings"
  type = map(object({
    origin  = optional(string)
    headers = optional(list(string))
    methods = optional(list(string))
  }))
  default = {}
}

variable "egress_engine" {
  description = "Input for egress engines."
  type        = map(any)
  default = {
    engineEgress = [
      {
        to = [{
          ipBlock = {
            cidr = "10.9.8.7/32"
          }
        }]
        ports = [
          {
            protocol = "TCP"
            port     = 443
          }
        ]
      }
    ]
  }
}


variable "vault_config" {
  description = "Input for vault secrets."
  type = object({
    git = map(object({
      name            = optional(string)
      url             = optional(string)
      kind            = optional(string)
      vault_namespace = optional(string)
      role_id         = optional(string)
      secret_name     = optional(string) # Should match the secret name created in the corresponding vault_secrets variable
    })),
    ecl = map(object({
      name            = optional(string)
      url             = optional(string)
      kind            = optional(string)
      vault_namespace = optional(string)
      role_id         = optional(string)
      secret_name     = optional(string) # Should match the secret name created in the corresponding vault_secrets variable
    })),
    ecluser = map(object({
      name            = optional(string)
      url             = optional(string)
      kind            = optional(string)
      vault_namespace = optional(string)
      role_id         = optional(string)
      secret_name     = optional(string) # Should match the secret name created in the corresponding vault_secrets variable
    }))
    esp = map(object({
      name            = optional(string)
      url             = optional(string)
      kind            = optional(string)
      vault_namespace = optional(string)
      role_id         = optional(string)
      secret_name     = optional(string) # Should match the secret name created in the corresponding vault_secrets variable
    }))
  })
  default = null
}


variable "egress" {
  description = "egress settings"
  type = object({
    dafilesrv_engine   = optional(string)
    dali_engine        = optional(string)
    dfuserver_name     = optional(string)
    eclagent_engine    = optional(string)
    eclccserver_engine = optional(string)
    esp_engine         = optional(string)
  })
  default = {
    dafilesrv_engine   = "engineEgress"
    dali_engine        = "engineEgress"
    dfuserver_name     = "engineEgress"
    eclagent_engine    = "engineEgress"
    eclccserver_engine = "engineEgress"
    esp_engine         = "engineEgress"
  }
}

variable "eclagent_settings" {
  description = "eclagent settings"
  type = map(object({
    replicas          = number
    maxActive         = number
    prefix            = string
    use_child_process = bool
    spillPlane        = optional(string, "spill")
    type              = string
    resources = object({
      cpu    = string
      memory = string
    })
    cost = object({
      perCpu = number
    })
    egress = optional(string)
  }))
  default = {
    hthor = {
      replicas          = 1
      maxActive         = 4
      prefix            = "hthor"
      use_child_process = false
      type              = "hthor"
      spillPlane        = "spill"
      resources = {
        cpu    = "1"
        memory = "4G"
      }
      egress = "engineEgress"
      cost = {
        perCpu = 1
      }
    },
  }
}

# variable "log_access_role_assignment" {
#   description = "Creates Role Assignment for enabling Log Access Viewer, ALA ZAP Reports"
#   type = object({
#     scope     = string
#     object_id = string
#   })
# }

variable "external_secrets" {
  type = object({
    enabled = bool
    namespace = optional(object({
      name   = string
      labels = map(string)
      }), {
      name = "external-secrets"
      labels = {
        name = "external-secrets"
      }
    })
    vault_secret_id = optional(object({
      name         = string
      secret_value = string
      }), {
      name         = "external-secrets-vault-secret-id"
      secret_value = ""
    })
    secret_stores = map(object({
      secret_store_name = string
      vault_url         = string
      vault_namespace   = string
      vault_kv_path     = string
      approle_role_id   = string
    }))
    secrets = map(object({
      target_secret_name = string
      remote_secret_name = string
      secret_store_name  = string
    }))
  })
  default = {
    enabled       = false
    secret_stores = {}
    secrets       = {}
  }
}

variable "vault_sync_cron_job" {
  description = "Enabling this variable schedules a cron job which will enable environments to shar K8s secrets by uploading to a given Vault KV. Secrets deployed with labels vault_destination will be discovered and sent to the Vault. Secrets can be labeled using esp_remoteclients variable."
  type = object({
    enabled = bool
    cron_job_settings = optional(object({
      schedule                      = optional(string, "0 */2 * * *") # Every 2 hours
      starting_deadline_seconds     = optional(number, 10)
      failed_jobs_history_limit     = optional(number, 5)
      successful_jobs_history_limit = optional(number, 5)
      backoff_limit                 = optional(number, 0)
      ttl_seconds_after_finished    = optional(number, 60)
      container_name                = optional(string, "vault-sync-cronjob")
      container_image               = optional(string)
      container_startup_command     = optional(list(string), ["python3", "vault_secret_sync.py"]) # Startup Command if you are using the Image Built by HPCC OPS
      container_environment_settings = optional(object({
        VAULT_ROLE_ID   = string,
        VAULT_SECRET_ID = string,
        VAULT_URL       = string,
        VAULT_NAMESPACE = string
        }), {
        VAULT_ROLE_ID   = "",
        VAULT_SECRET_ID = "",
        VAULT_NAMESPACE = "",
        VAULT_URL       = "https://vault.cluster.us-vault-prod.azure.lnrsg.io"
      })
    }))
  })
  default = {
    enabled = false
  }
}
