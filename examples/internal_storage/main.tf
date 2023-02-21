provider "azurerm" {
  tenant_id       = module.azure_credentials.tenant_id
  subscription_id = module.azure_credentials.subscription_id
  client_id       = module.azure_credentials.client_id
  client_secret   = module.azure_credentials.client_secret
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
  product_name        = "<product-name>"
  business_unit       = "infra"
  product_group       = "hpccops"
  subscription_id     = data.azurerm_subscription.current.subscription_id
  subscription_type   = "<lifecycle>"
  resource_group_type = "app"
}

module "resource_group" {
  source   = "git@github.com:Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.0"
  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}


#############
##vnet##
#############
module "virtual_network" {
  source  = "tfe.lnrisk.io/Infrastructure/virtual-network/azurerm"
  version = "6.0.0"

  naming_rules        = module.naming.yaml
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = [var.cidr_block]
  dns_servers   = [local.firewall_ip]

  route_tables = {
    default = local.route_table
  }

  subnets = {
    iaas-outbound = {
      cidrs                                          = [var.cidr_block_acr]
      allow_internet_outbound                        = true
      allow_lb_inbound                               = true
      allow_vnet_inbound                             = true
      allow_vnet_outbound                            = true
      configure_nsg_rules                            = true
      create_network_security_group                  = true
      enforce_private_link_endpoint_network_policies = false
      route_table_association                        = "default"
      service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
    }
  }

  aks_subnets = {
    hpcc = {
      subnet_info = {
        cidrs                                          = [var.cidr_block_app]
        service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
        enforce_private_link_endpoint_network_policies = true
        enforce_private_link_service_network_policies  = true
      }

      route_table = local.route_table
    }
  }

  peers = {
    expressroute = {
      id                           = var.expressroute_id
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = true
    }
  }
}


# ############
# #aks##
# #############
module "aks" {
  source              = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1.0.0-beta.26"
  location            = module.metadata.location
  resource_group_name = module.resource_group.name
  tags                = module.metadata.tags
  experimental = {
    oms_agent                      = true
    oms_log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id
    workspace_log_categories       = "limited"
    node_group_os_config           = true
  }
  cluster_name                        = local.cluster_name
  cluster_version                     = local.cluster_version
  network_plugin                      = "kubenet"
  sku_tier_paid                       = true
  cluster_endpoint_public_access      = true
  cluster_endpoint_access_cidrs       = ["0.0.0.0/0"]
  virtual_network_resource_group_name = module.resource_group.name
  virtual_network_name                = module.virtual_network.vnet.name
  subnet_name                         = module.virtual_network.aks.hpcc.subnet.name
  route_table_name                    = module.virtual_network.aks.hpcc.route_table.name
  dns_resource_group_lookup           = { "${local.internal_domain}" = local.dns_resource_group }
  admin_group_object_ids              = [var.aad_group_id]
  rbac_bindings                       = var.rbac_bindings
  node_groups                         = local.node_groups

  core_services_config = {
    alertmanager = {
      smtp_host = local.smtp_host
      smtp_from = local.smtp_from
      routes    = local.alert_manager_routes
      receivers = local.alert_manager_recievers
    }

    coredns = {
      forward_zones = {
        "risk.regn.net"     = local.firewall_ip
        "ins.risk.regn.net" = local.firewall_ip
        "prg.risk.regn.net" = local.firewall_ip
        "hc.risk.regn.net"  = local.firewall_ip
        "rs.lexisnexis.net" = local.firewall_ip
        "noam.lnrm.net"     = local.firewall_ip
        "eu.lnrm.net"       = local.firewall_ip
        "seisint.com"       = local.firewall_ip
        "sds"               = local.firewall_ip
        "internal.sds"      = local.firewall_ip
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
    grafana = {
      admin_password = local.grafana_admin_password
    }
    ingress_internal_core = {
      domain           = local.internal_domain
      subdomain_suffix = local.cluster_name_short
      public_dns       = true
    }
    ingress_core_internal = {
      domain = local.internal_domain
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
  acr_contributors              = { aks = module.aks.kubelet_identity.object_id }
  access_list                   = local.acr_trusted_ips
  service_endpoints = {
    "iaas-outbound" = module.virtual_network.subnets["iaas-outbound"].id
  }
}


#################
##hpcc##
#################
module "hpcc" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-hpcc.git?ref=main"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.metadata.tags
  environment         = var.environment
  productname         = var.productname
  cluster_name        = local.cluster_name
  internal_domain     = local.internal_domain

  namespace = {
    name = "hpcc"
    labels = {
      name = "hpcc"
    }
  }

  hpcc_container               = var.jfrog_registry
  hpcc_container_registry_auth = var.jfrog_auth
  helm_chart_version           = var.jfrog_registry.version


  install_blob_csi_driver = true
  enable_node_tuning      = false
  node_tuning_containers  = var.node_tuning_containers



  environment_variables = {
    SMTPserver         = "appmail-bct.risk.regn.net"
    emailSenderAddress = "eclsystem@lexisnexisrisk.com"
    subscription       = local.account_code
  }

  admin_services_node_selector = { all = { workload = "servpool" } }

  admin_services_storage_account_settings = {
    replication_type     = "ZRS"
    authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.response_body })
    delete_protection    = false
    subnet_ids = merge({
      "aks-hpcc" = module.virtual_network.aks.hpcc.subnet.id
    }, var.azure_admin_subnets)
  }

  data_storage_config = {
    internal = {
      blob_nfs = {
        data_plane_count = var.hpcc_data_plane_count
        storage_account_settings = {
          replication_type     = "ZRS"
          authorized_ip_ranges = merge(var.storage_account_authorized_ip_ranges, { my_ip = data.http.my_ip.response_body })
          delete_protection    = false
          subnet_ids = merge({
            "aks-hpcc" = module.virtual_network.aks.hpcc.subnet.id
          }, var.azure_admin_subnets)
        }
      }
      hpc_cache = null
    }
    external = null
  }

  admin_services_storage = {
    dali = {
      size = 200
      type = "azurefiles"
    }
    debug = {
      size = 100
      type = "blobnfs"
    }
    dll = {
      size = 1000
      type = "blobnfs"
    }
    lz = {
      size = 1000
      type = "blobnfs"
    }
    sasha = {
      size = 10000
      type = "blobnfs"
    }
  }

  ldap_config = {}

  # Example Ldap Config


  # ldap_config = {
  #   dali = {
  #     adminGroupName      = var.ldap_adminGroupName
  #     filesBasedn         = var.ldap_filesBasedn
  #     groupsBasedn        = var.ldap_groupsBasedn
  #     hpcc_admin_password = var.ldap_pass
  #     hpcc_admin_username = var.ldap_user
  #     ldap_admin_password = var.ldap_pass
  #     ldap_admin_username = var.ldap_user
  #     ldapAdminVaultId    = ""
  #     resourcesBasedn     = var.ldap_resourcesBasedn
  #     sudoersBasedn       = var.ldap_sudoersBasedn
  #     systemBasedn        = var.ldap_systemBasedn
  #     usersBasedn         = var.ldap_usersBasedn
  #     workunitsBasedn     = var.ldap_workunitsBasedn
  #   }
  #   esp = {
  #     adminGroupName      = var.ldap_adminGroupName
  #     filesBasedn         = var.ldap_filesBasedn
  #     groupsBasedn        = var.ldap_groupsBasedn
  #     ldap_admin_password = var.ldap_pass
  #     ldap_admin_username = var.ldap_user
  #     ldapAdminVaultId    = ""
  #     resourcesBasedn     = var.ldap_resourcesBasedn
  #     sudoersBasedn       = var.ldap_sudoersBasedn
  #     systemBasedn        = var.ldap_systemBasedn
  #     usersBasedn         = var.ldap_usersBasedn
  #     workunitsBasedn     = var.ldap_workunitsBasedn
  #   }
  #   ldap_server = var.ldap_server
  # }

  dali_settings = {
    coalescer = {
      interval     = 12
      at           = "* * * * *"
      minDeltaSize = 50000
      resources = {
        cpu    = "1"
        memory = "4G"
      }
    }
    resources = {
      cpu    = "4"
      memory = "24G"
    }
  }

  sasha_config = {
    disabled = false
    wu-archiver = {
      disabled = false
      service = {
        servicePort = 8877
      }
      plane           = "sasha"
      interval        = 6
      limit           = 1000
      cutoff          = 8
      backup          = 0
      at              = "* * * * *"
      throttle        = 0
      retryinterval   = 7
      keepResultFiles = false
    }

    dfuwu-archiver = {
      disabled = false
      service = {
        servicePort = 8877
      }
      plane    = "sasha"
      interval = 24
      limit    = 1000
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

  dfuserver_settings = {
    maxJobs = 6
    resources = {
      cpu    = "1"
      memory = "2G"
    }
  }

  spray_service_settings = {
    replicas     = 6
    nodeSelector = "spraypool"
  }

  # Add your Firewall rules here, to which you need outbound connectivity.
  egress_engine = {
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


  eclagent_settings = {
    hthor = {
      replicas          = 1
      maxActive         = 4
      prefix            = "hthor"
      use_child_process = false
      type              = "hthor"
      resources = {
        cpu    = "1"
        memory = "4G"
      }
      egress = "engineEgress"
    },
    "roxie-workunit" = {
      replicas          = 1
      maxActive         = 20
      prefix            = "roxie-workunit"
      use_child_process = true
      type              = "roxie"
      resources = {
        cpu    = "1"
        memory = "4G"
      }
      egress = "engineEgress"
    }
  }

  spill_volume_size = 600 # maps to local ssd space specific to DDSv4 series, number in Gi

  thor_config = [
    {
      name                = "thor-nonphidelivery" #configmap throws errors if you include underbars, or if the name is longer than 27 characters (because it tries making a secret that needs to be 63 char or less
      disabled            = false
      prefix              = "thor-nonphidelivery"
      numWorkers          = 200
      maxJobs             = 12
      maxGraphs           = 6
      maxGraphStartupTime = 172800
      keepJobs            = "none"
      numWorkersPerPod    = 1
      nodeSelector        = { workload = "thorpool" }
      tolerations_value   = "thorpool"
      egress              = "engineEgress"
      managerResources = {
        cpu    = 2
        memory = "8G"
      }
      workerResources = {
        cpu    = 4
        memory = "16G"
      }
      workerMemory = {
        query      = "12G"
        thirdParty = "500M"
      }
      eclAgentResources = {
        cpu    = 2
        memory = "8G"
      }
    },
    {
      name                = "thor-nonphideliveryuat"
      disabled            = false
      prefix              = "thor-nonphideliveryuat"
      numWorkers          = 200
      maxJobs             = 6
      maxGraphs           = 3
      maxGraphStartupTime = 172800
      keepJobs            = "none"
      numWorkersPerPod    = 1
      nodeSelector        = { workload = "thorpool" }
      tolerations_value   = "thorpool"
      egress              = "engineEgress"
      managerResources = {
        cpu    = 2
        memory = "8G"
      }
      workerResources = {
        cpu    = 4
        memory = "16G"
      }
      workerMemory = {
        query      = "12G"
        thirdParty = "500M"
      }
      eclAgentResources = {
        cpu    = 2
        memory = "8G"
      }
    }
  ]

  eclccserver_settings = {
    "myeclccserver" = {
      useChildProcesses = false
      replicas          = 1
      maxActive         = 4
      resources = {
        cpu    = "12"
        memory = "48G"
      }
      egress                = "engineEgress"
      gitUsername           = "svc-hpcc-pubrec-git"
      childProcessTimeLimit = "86400"
    }
  }
}