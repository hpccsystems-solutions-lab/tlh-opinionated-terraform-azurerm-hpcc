module "roxie" {
  depends_on = [
    module.aks,
    module.hpcc_data_storage,
    module.hpcc_data_cache,
    module.thor
  ]

  source = "../../"

  helm_chart_version           = var.hpcc_helm_chart_version
  hpcc_container               = var.hpcc_container
  hpcc_container_registry_auth = var.hpcc_container_registry_auth

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  namespace = {
    name = "roxie"
    labels = {
      name = "roxie"
    }
  }

  enable_node_tuning      = false
  install_blob_csi_driver = false

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
    internal = null
    external = {
      blob_nfs  = null
      hpc_cache = module.hpcc_data_cache.data_planes["external"]
      hpcc      = null
    }
  }

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
}