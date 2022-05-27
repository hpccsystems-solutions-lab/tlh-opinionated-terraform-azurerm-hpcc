###############
module "hpcc_cluster" {
  depends_on = [
    module.aks,
  ]

  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-hpcc.git?ref=v0.7.3"

  helm_chart_version = var.hpcc_helm_chart_version
  hpcc_container     = var.hpcc_container

  hpcc_container_registry_auth = var.container_registry_auth

  resource_group_name = module.resource_group_eastus.name
  location            = module.metadata_eastus.location
  tags                = module.metadata_eastus.tags

  namespace = {
    name = "hpcc"
    labels = {
      name = "hpcc"
    }
  }

  enable_node_tuning      = false
  install_blob_csi_driver = true

  admin_services_storage_account_settings = {
    replication_type     = "ZRS"
    authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
    delete_protection    = false
    subnet_ids = merge({
      private = module.virtual_network_eastus.aks["roxie"].subnets["private"].id

    }, var.azure_admin_subnets)
  }

  data_storage_config = {
    internal = null
    external = {
      blob_nfs = null
      hpc_cache = [{
        id     = "1"
        server = "boolroxie-hpc-cache.us-prnonfcraroxie-prod.azure.lnrsg.io"
        path   = "/boolean"
      }]
      hpcc = null
    }
  }

  ldap_config = {
    dali = {
      adminGroupName      = var.ldap_adminGroupName
      filesBasedn         = var.ldap_filesBasedn
      groupsBasedn        = var.ldap_groupsBasedn
      hpcc_admin_password = var.ldap_pass
      hpcc_admin_username = var.ldap_user
      ldap_admin_password = var.ldap_pass
      ldap_admin_username = var.ldap_user
      ldapAdminVaultId    = ""
      resourcesBasedn     = var.ldap_resourcesBasedn
      sudoersBasedn       = var.ldap_sudoersBasedn
      systemBasedn        = var.ldap_systemBasedn
      usersBasedn         = var.ldap_usersBasedn
      workunitsBasedn     = var.ldap_workunitsBasedn
    }
    esp = {
      adminGroupName      = var.ldap_adminGroupName
      filesBasedn         = var.ldap_filesBasedn
      groupsBasedn        = var.ldap_groupsBasedn
      ldap_admin_password = var.ldap_pass
      ldap_admin_username = var.ldap_user
      ldapAdminVaultId    = ""
      resourcesBasedn     = var.ldap_resourcesBasedn
      sudoersBasedn       = var.ldap_sudoersBasedn
      systemBasedn        = var.ldap_systemBasedn
      usersBasedn         = var.ldap_usersBasedn
      workunitsBasedn     = var.ldap_workunitsBasedn
    }
    ldap_server = var.ldap_server
  }

  roxie_config = [
    {
      name     = "roxie"
      disabled = false
      prefix   = "roxie"
      checkFileDate = var.checkFileDate
      logFullQueries = var.logFullQueries
      copyResources = var.copyResources
      parallelLoadQueries = var.parallelLoadQueries
      nodeSelector        = {}
      services = [
        {
          name        = "roxie"
          servicePort = 9876
          listenQueue = var.listenQueue
          numThreads  = var.numThreads
          visibility  = var.visibility
        }
      ]
      replicas       = var.replicas
      numChannels    = var.numChannels
      serverReplicas = var.serverReplicas
      traceLevel = var.traceLevel
      soapTraceLevel = var.soapTraceLevel
      traceRemoteFiles = var.traceRemoteFiles
      topoServer = {
        replicas = var.topoServer_replicas
      }
      channelResources = {
        cpu    = var.channelResources_cpu
        memory = var.channelResources_memory
      }
    }
  ]

  thor_config = [{
    name             = "thor"
    disabled         = true
    prefix           = "thor"
    numWorkers       = 1
    maxJobs          = 2
    maxGraphs        = 2
    numWorkersPerPod = 1
    keepJobs         = "none"
    nodeSelector     = {}
    managerResources = {
      cpu    = 1
      memory = "2G"
    }
    workerResources = {
      cpu    = 1
      memory = "1G"
    }
    workerMemory = {
      query      = "1G"
      thirdParty = "100M"
    }
    eclAgentResources = {
      cpu    = 1
      memory = "1G"
    }
  }]
}
