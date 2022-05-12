module "thor" {
  depends_on = [
    module.aks,
    module.hpcc_data_storage,
    module.hpcc_data_cache
  ]

  source = "../../"

  helm_chart_version           = var.hpcc_helm_chart_version
  hpcc_container               = var.hpcc_container
  hpcc_container_registry_auth = var.hpcc_container_registry_auth

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  namespace = {
    name = "thor"
    labels = {
      name = "thor"
    }
  }

  admin_services_storage_account_settings = {
    replication_type     = "LRS"
    authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
    delete_protection    = false
    subnet_ids = {
      aks = module.virtual_network.aks.demo.subnet.id
    }
  }

  data_storage_config = {
    internal = null
    external = {
      blob_nfs  = module.hpcc_data_storage.data_planes
      hpc_cache = null
      hpcc      = null
    }
  }

  spill_volume_size = "75"

  roxie_config = [
    {
      name     = "roxie"
      disabled = false
      prefix   = "roxie"
      services = [
        {
          name        = "roxie"
          servicePort = 9876
          listenQueue = 200
          numThreads  = 30
          visibility  = "local"
        }
      ]
      replicas       = 2
      numChannels    = 2
      serverReplicas = 0
      topoServer = {
        replicas = 1
      }
    }
  ]

  thor_config = [{
    name             = "thor"
    disabled         = false
    prefix           = "thor"
    numWorkers       = 5
    keepJobs         = "none"
    maxJobs          = 4
    maxGraphs        = 2
    numWorkersPerPod = 1
    managerResources = {
      cpu    = 1
      memory = "2G"
    }
    workerResources = {
      cpu    = 3
      memory = "4G"
    }
    workerMemory = {
      query      = "3G"
      thirdParty = "500M"
    }
    eclAgentResources = {
      cpu    = 1
      memory = "2G"
    }
  }]
}