provider "azurerm" {
  tenant_id = module.azure_credentials.tenant_id
  subscription_id = module.azure_credentials.subscription_id
  client_id = module.azure_credentials.client_id
  client_secret = module.azure_credentials.client_secret
  features {}
}

module "naming" {
  source = "github.com/Azure-Terraform/example-naming-template.git?ref=v1.0.0"
}

resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

module "metadata" {
    source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.0"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "hpccops"
  location            = "eastus2"
  sre_team            = "SupercomputerOps@lexisnexisrisk.com"
  environment         = "sandbox"
  product_name        = "prct"
  business_unit       = "infra"
  product_group       = "hpccops"
  subscription_id     = data.azurerm_subscription.current.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.0"
  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}


#############
##vnet##
#############
module "virtual_network" {

  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v6.0.0"

  naming_rules        = module.naming.yaml
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  address_space = [var.cidr_block_prctroxieaks]
  subnets = {
    iaas-outbound = {
      cidrs                                          = [var.cidr_block_prctroxieacr]
      allow_internet_outbound                        = true
      allow_lb_inbound                               = true
      allow_vnet_inbound                             = true
      allow_vnet_outbound                            = true
      configure_nsg_rules                            = true
      create_network_security_group                  = true
      enforce_private_link_endpoint_network_policies = false
      service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
    }
  }
  aks_subnets = {
    roxie = {
      private = {
        cidrs                                          = [var.cidr_block_prctroxieaks_roxie]
        service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
        enforce_private_link_endpoint_network_policies = true
        enforce_private_link_service_network_policies  = true
      }
      public = {
        cidrs                                          = [var.cidr_block_prctroxieaks_storage]
        service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
        enforce_private_link_endpoint_network_policies = true
        enforce_private_link_service_network_policies  = true
      }

      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          internal-1 = {
            address_prefix         = "10.0.0.0/8"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = var.firewall_ip
          }
          internal-2 = {
            address_prefix         = "172.16.0.0/12"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = var.firewall_ip
          }
          internal-3 = {
            address_prefix         = "192.168.0.0/16"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = var.firewall_ip
          }
          local-vnet = {
            address_prefix = var.cidr_block_prctroxieaks
            next_hop_type  = "VnetLocal"
          }
        }
      }
    }
  }
}


# ############
# #aks##
# #############
module "aks" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.13"

  depends_on = [
    module.virtual_network
  ]

  location            = module.metadata.location
  resource_group_name = module.resource_group.name

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  sku_tier_paid   = false

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]

  virtual_network_resource_group_name = module.resource_group.name
  virtual_network_name                = module.virtual_network.vnet.name
  subnet_name                         = module.virtual_network.aks.demo.subnet.name
  route_table_name                    = module.virtual_network.aks.demo.route_table.name

  dns_resource_group_lookup = { "${local.internal_domain}" = local.dns_resource_group }

  azuread_clusterrole_map         = local.azuread_clusterrole_map

  node_group_templates = [
    {
      name                = "workers"
      node_os             = "ubuntu"
      node_type           = "gp"
      node_type_version   = "v1"
      node_size           = "large"
      single_group        = false
      min_capacity        = 0
      max_capacity        = 18
      placement_group_key = null
      labels = {
        "lnrs.io/tier" = "standard"
      }
      taints = []
      tags   = {}
    }
  ]

  core_services_config = {
    alertmanager = {
      smtp_host = local.smtp_host
      smtp_from = local.smtp_from
      routes    = local.alert_manager_routes
      receivers = local.alert_manager_recievers
    }

    coredns = {
      forward_zones = {
        "risk.regn.net"     = var.firewall_ip
        "ins.risk.regn.net" = var.firewall_ip
        "prg.risk.regn.net" = var.firewall_ip
        "hc.risk.regn.net"  = var.firewall_ip
        "rs.lexisnexis.net" = var.firewall_ip
        "noam.lnrm.net"     = var.firewall_ip
        "eu.lnrm.net"       = var.firewall_ip
        "seisint.com"       = var.firewall_ip
        "sds"               = var.firewall_ip
        "internal.sds"      = var.firewall_ip
      }
    }

    external_dns = {
      zones               = local.internal_domain
      resource_group_name = local.dns_resource_group
    }

    cert_manager = {
      letsencrypt_environment = "staging"
      letsencrypt_email       = null
      dns_zones = {
        "${local.internal_domain}" = local.dns_resource_group
      }
    }

    ingress_internal_core = {
      domain           = local.internal_domain
      subdomain_suffix = local.cluster_name_short
      public_dns       = true
    }

  }
}


# ##############
# ##acr###
# ##############

module "acr" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-container-registry.git?ref=v2.4.0"

  location            = module.metadata.location
  resource_group_name = module.resource_group.name
  names               = module.metadata.names
  tags                = module.metadata.tags

  georeplications = [
    {
      location = "centralus"
      tags     = { "purpose" = "Primary DR Region" }
    }
  ]

  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
  disable_unique_suffix         = true
  acr_admins                    = local.azuread_clusterrole_map.cluster_admin_users
  acr_contributors = { aks = module.aks.kubelet_identity.object_id }
  access_list                   = local.acr_trusted_ips
  service_endpoints = {
    "iaas-outbound" = module.virtual_network.subnets["iaas-outbound"].id
  }
}


#################
##hpcc##
#################
module "hpcc" {
  depends_on = [
    module.aks
  ]

  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-hpcc.git?ref=v0.8.1"

  environment = "dev"
  productname = "prctrox"

  helm_chart_version           = var.hpcc_helm_chart_version
  hpcc_container               = var.hpcc_container
  hpcc_container_registry_auth = var.hpcc_container_registry_auth

  node_tuning_container_registry_auth = var.hpcc_container_registry_auth

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags

  helm_chart_timeout  = 1000

  namespace = {
    name = "hpcc"
    labels = {
      name = "hpcc"
    }
  }

  admin_services_storage_account_settings = {
    replication_type     = "ZRS"
    authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
    delete_protection    = false

    subnet_ids = merge({
      aks = module.virtual_network.subnets["iaas-outbound"].id
    }, var.azure_admin_subnets)
  }

    data_storage_config = {
      internal = {
        blob_nfs = {
          data_plane_count = 1
          storage_account_settings = {
            replication_type     = "ZRS"
            authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.body })
            delete_protection    = false
 
            subnet_ids = merge({
              aks = module.virtual_network.subnets["iaas-outbound"].id
            },  var.azure_admin_subnets)
          }
        }
        hpc_cache = null
      }
      external = null
    }


    spill_volume_size = 150

    thor_config = [{
      name             = "thor"
      disabled         = false
      prefix           = "thor"
      numWorkers       = 5
      keepJobs         = "none"
      maxJobs          = 4
      maxGraphs        = 2
      numWorkersPerPod = 1
      nodeSelector = {
        workload = "thorpool"
      }
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


     roxie_config = [
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