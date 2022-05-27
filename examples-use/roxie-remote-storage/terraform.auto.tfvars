resource_group = 
cidr_block_aks_eastus         = "10.146.157.0/24"
cidr_block_aks_app_eastus     = "10.146.157.0/25"
cidr_block_aks_storage_eastus = "10.146.157.128/25"
azuread_clusterrole_map = {
  cluster_admin_users = {
    "wagnerrh@risk.regn.net" = "272aa8b3-a811-4be6-9d8f-60f317b2af97"
    "orocheex@risk.regn.net" = "464d3990-d153-4022-859f-038593f0b3ed"
    "fernanux@risk.regn.net" = "f3757f75-96dc-4c92-8fde-f029b42100b7"
  }
  cluster_view_users   = {}
  standard_view_users  = {}
  standard_view_groups = {}
}
api_server_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30/32"
}
storage_account_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}
core_services_config = {
  alertmanager = {
    smtp_host = "smtp.foo.bar"
    smtp_from = "wagnerrh@risk.regn.net"
    receivers = [{ name = "alerts", email_configs = [{ to = "wagnerrh@risk.regn.net", require_tls = false }] }]
  }

  ingress_internal_core = {
    domain = "us-prbooleanrox-dev.azure.lnrsg.io"
  }

  external_dns = {
    zones               = ["us-prbooleanrox-dev.azure.lnrsg.io"]
    resource_group_name = "app-dns-prod-eastus2"
  }
  cert_manager = {
    letsencrypt_environment = "staging"
    letsencrypt_email       = "wagnerrh@risk.regn.net"
    dns_zones = {
      "us-prbooleanrox-dev.azure.lnrsg.io" = "app-dns-prod-eastus2"
    }
    azure_environment = "AzurePublicCloud"
  }
}
cidr_block_aks_bool    = "10.239.160.0/23"
boolroxie_prod_vnet_id = "/subscriptions/02a6ed56-3583-4d5e-a4f5-120c5597ad0b/resourceGroups/app-boolroxie-dev-eastus2/providers/Microsoft.Network/virtualNetworks/hpccops-dev-eastus2-vnet"
# Excluding hpcc-data, since it is remote
hpcc_storage_config = {
  #data = {
  #  size           = "10Gi"
  #  container_name = ""
  #}
  dali = {
    size           = "1Gi"
    container_name = ""
  }
  dll = {
    size           = "1Gi"
    container_name = ""
  }
  sasha = {
    size           = "1Gi"
    container_name = ""
  }
  mydropzone = {
    size           = "1Gi"
    container_name = ""
  }
}

# LDAP
ldap_server          = "10.173.0.9"
ldap_adminGroupName  = "HPCCAdmin"
ldap_filesBasedn     = "ou=files,ou=ecl"
ldap_groupsBasedn    = "ou=groups,ou=ecl"
ldap_resourcesBasedn = "ou=fcralogssmc,ou=EspServices,ou=ecl"
ldap_sudoersBasedn   = "ou=SUDOers"
ldap_systemBasedn    = "cn=Users"
ldap_usersBasedn     = "ou=users,ou=ecl"
ldap_workunitsBasedn = "ou=workunits,ou=logsthor,ou=ecl"

# Helm
hpcc_helm_chart_version = "8.6.26-rc1"
hpcc_container = { "image_name" = "hpccoperations/platform-core-ln", "image_root" = "eastboolacr.azurecr.io", "version" = "8.6.26-rc1"}

# Roxie Settings
checkFileDate = false
logFullQueries = true
copyResources = false
parallelLoadQueries = 1
listenQueue = 200
numThreads = 30
visibility = "local"
replicas = 1
numChannels = 10
serverReplicas = 0
traceLevel = 5
soapTraceLevel = 5
traceRemoteFiles = false
topoServer_replicas = 1
channelResources_cpu = 2
channelResources_memory = "24G"


