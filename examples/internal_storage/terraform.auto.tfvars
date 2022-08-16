cidr_block_prctroxieaks         = "10.231.4.0/22"
cidr_block_prctroxieacr         = "10.231.7.128/26"
cidr_block_prctroxieaks_roxie   = "10.231.4.0/24"
cidr_block_prctroxieaks_storage = "10.231.7.192/26"

default_connection_info = null
api_server_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}
private_cidrs = ["10.239.141.0/25"]
public_cidrs  = ["10.239.141.128/26"]
storage_account_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}
hpcc_storage_config = {
  data = {
    size           = "100Gi"
    container_name = ""
  }
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

# Registry
hpcc_helm_chart_version = "8.8.0-rc6"


hpcc_container = {
  image_root = "prctnonprodcr.azurecr.io/hpccoperations",
  image_name = "platform-core-ln",
  version = "8.6.38"
}


jfrog_registry = {
  image_root = "useast.jfrog.lexisnexisrisk.com/hpccpl-docker-nonprod-virtual",
  image_name = "platform-core-ln",
  version    = "8.6.20-rc1"
}
container_registry_auth = {
  username = "wagnerrh@risk.regn.net",
  password = "AKCp8mYUomCJV4Z3ki2jHJP9ZvV3AiFg4aRYWxSueummgupdyskKN2PqoZ3gUFGx8nhJtHE8Z"
}

#### Cache Storage target DNS 
hpc_cache_dns_name = {
  zone_name                = "us-infrastructure-dev.azure.lnrsg.io"
  zone_resource_group_name = "app-dns-prod-eastus2"
}

# hpc_cache_name = "hpc-cache-blob-data"

###
environment = "dev"