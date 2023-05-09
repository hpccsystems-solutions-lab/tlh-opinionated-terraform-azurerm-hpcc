locals {
  account_code = "us-<productname>-<lifecycle>"

  cluster_name = "<aks-cluster-name>"

  cluster_version = "1.23"

  dns_resource_group = "app-dns-prod-eastus2"

  internal_domain = "us-<productname>-<lifecycle>.azure.lnrsg.io"

  cluster_name_short = trimprefix(local.cluster_name, "${local.account_code}-")

  acr_trusted_ips = {
    tfe   = "20.69.219.180/32"
    boca  = "209.243.48.0/20"
    india = "103.231.79.16/28"
    ntt   = "83.231.190.16/28"
    ntt2  = "83.231.235.0/24"
    uk    = "89.149.148.0/24" # London VPN
    ala   = "66.241.32.0/19"  # Alpharetta VPN
    ngd   = "77.67.50.160/28"
    vpn   = "52.177.80.30/32" # includes vault
  }

  node_groups = {
    thorpool = {
      node_type         = "gpd"
      node_type_version = "v1"
      node_size         = "8xlarge"
      max_capacity      = 309
      os_config = {
        sysctl = {
          net_ipv4_tcp_keepalive_time = 200
        }
      }
      labels = {
        "lnrs.io/tier" = "standard"
        "workload"     = "thorpool"
      }
    },

    spraypool = {
      node_type         = "gp"
      node_type_version = "v1"
      node_size         = "xlarge"
      min_capacity      = 3
      max_capacity      = 3
      os_config = {
        sysctl = {
          net_ipv4_tcp_keepalive_time = 200
        }
      }
      single_group = false
      labels = {
        "lnrs.io/tier"  = "standard"
        "workload"      = "spraypool"
        "spray-service" = "spraypool"
      }
    },
    servpool = {
      node_type         = "gpd"
      node_type_version = "v1"
      node_size         = "4xlarge"
      max_capacity      = 9
      os_config = {
        sysctl = {
          net_ipv4_tcp_keepalive_time = 200
        }
      }
      labels = {
        "lnrs.io/tier" = "standard"
        "workload"     = "servpool"
      }
    }
  }

  internal_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  firewall_ip  = "<your-firewall-hub-ip>"

  routes = merge(
    {
      internet = {
        address_prefix = "0.0.0.0/0"
        next_hop_type  = "Internet"
      }
      local-vnet = {
        address_prefix = var.cidr_block
        next_hop_type  = "VnetLocal"
      }
    },
    { for ip in local.internal_ips :
      format("internal-%s", index(local.internal_ips, ip) + 1) => {
        address_prefix         = ip
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = local.firewall_ip
      }
  })

  route_table = {
    routes                        = local.routes
    disable_bgp_route_propagation = true
    use_inline_routes             = false
  }


  k8s_exec_auth_env = {
    AAD_SERVICE_PRINCIPAL_CLIENT_ID     = module.azure_credentials.client_id
    AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = module.azure_credentials.client_secret
  }

  azure_auth_env = {
    AZURE_TENANT_ID       = module.azure_credentials.tenant_id
    AZURE_SUBSCRIPTION_ID = module.azure_credentials.subscription_id
    AZURE_CLIENT_ID       = module.azure_credentials.client_id
    AZURE_CLIENT_SECRET   = module.azure_credentials.client_secret
  }

  admin_group_object_ids = [var.aad_group_id]


}