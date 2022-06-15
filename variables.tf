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
    authorized_ip_ranges = map(string)
    delete_protection    = bool
    replication_type     = string
    subnet_ids           = map(string)
  })
  default = {
    authorized_ip_ranges = {}
    delete_protection    = false
    replication_type     = "ZRS"
    subnet_ids           = {}
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
          authorized_ip_ranges = map(string)
          delete_protection    = bool
          replication_type     = string
          subnet_ids           = map(string)
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
          authorized_ip_ranges = {}
          delete_protection    = false
          replication_type     = "ZRS"
          subnet_ids           = {}
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
    checkScopeScans               = true
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
    disabled            = bool
    name                = string
    nodeSelector        = map(string)
    numChannels         = number
    prefix              = string
    replicas            = number
    serverReplicas      = number
    checkFileDate       = bool
    logFullQueries      = bool
    copyResources       = bool
    parallelLoadQueries = number
    traceLevel          = number
    soapTraceLevel      = number
    traceRemoteFiles    = bool
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
      disabled            = true
      name                = "roxie"
      nodeSelector        = {}
      numChannels         = 2
      prefix              = "roxie"
      replicas            = 2
      serverReplicas      = 0
      checkFileDate       = false
      logFullQueries      = false
      copyResources       = false
      logFullQueries      = false
      parallelLoadQueries = 1
      traceLevel          = 1
      soapTraceLevel      = 1
      traceRemoteFiles    = false
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
        memory = "4Gi"
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
