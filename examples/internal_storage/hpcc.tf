module "hpcc" {
  depends_on = [
    module.aks
  ]

  source = "../../"

  helm_chart_version           = var.hpcc_helm_chart_version
  hpcc_container               = var.hpcc_container
  hpcc_container_registry_auth = var.hpcc_container_registry_auth

  node_tuning_container_registry_auth = var.hpcc_container_registry_auth

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
        data_plane_count = 2
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
      hpc_cache = {
        dns = {
          zone_name                = "infrastructure-sandbox.us.lnrisk.io"
          zone_resource_group_name = "rg-iog-sandbox-eastus2-lnriskio"
        }
        resource_provider_object_id = data.azuread_service_principal.hpc_cache_resource_provider.object_id
        size                        = "small"
        cache_update_frequency = "3h"
        storage_account_data_planes = null
        subnet_id = module.virtual_network.aks["demo"].subnets.private.id
      }
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
