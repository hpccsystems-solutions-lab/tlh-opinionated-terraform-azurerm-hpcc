module "hpcc" {
  depends_on = [
    module.aks
  ]

  source = "../../"

  helm_chart_version = var.hpcc_helm_chart_version
  container_registry = var.hpcc_container_registry

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  namespace = {
    name = "hpcc"
    labels = {
      name = "hpcc"
    }
  }

  admin_services_storage_account_settings = {
    replication_type     = "LRS"
    authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
    delete_protection    = false
    subnet_ids = {
      public  = module.virtual_network.aks["demo"].subnets.public.id
      private = module.virtual_network.aks["demo"].subnets.private.id
    }
  }

  data_storage_config = {
    internal = {
      blob_nfs = {
        data_plane_count = 5
        storage_account_settings = {
          replication_type     = "LRS"
          authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
          delete_protection    = false
          subnet_ids = {
            public  = module.virtual_network.aks["demo"].subnets.public.id
            private = module.virtual_network.aks["demo"].subnets.private.id
          }
        }

      }
      hpc_cache = null
    }
    external = null
  }

  spill_volume_size = "150Gi"

  thor_config = [{
    name             = "thor"
    disabled         = true
    prefix           = "thor"
    numWorkers       = 5
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
