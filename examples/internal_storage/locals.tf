locals {
  account_code = "us-prctrox-dev"

  cluster_name = "us-kg-aks-009"

  cluster_version = "1.21"

  dns_resource_group = "app-dns-prod-eastus2"

  internal_domain = "us-prctrox-dev.azure.lnrsg.io"

  cluster_name_short = trimprefix(local.cluster_name, "${local.account_code}-")
  azuread_clusterrole_map = {
    cluster_admin_users = {
      "gianmi01@risk.regn.net" = "d51096fd-443e-492b-a07b-cfd462cd9e4e"
      "sadika01@risk.regn.net" = "19983b89-67ea-4bda-989d-365b1b9310fc"
      "sreych01@risk.regn.net" = "dbd7c8f3-80d3-4b83-9c08-65ad27bdbf44"
      "guzmki01@risk.regn.net" = "b326fe2c-1d5d-4baf-b872-6f21ba9659cb"
    }
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }

  grafana_admin_password  = random_string.random.result
  smtp_host               = "smtp.lexisnexisrisk.com:25"
  smtp_from               = "ioa-eks-1@lexisnexisrisk.com"
  alert_manager_routes    = []
  alert_manager_recievers = []

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

 azure_auth_env = {
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
  }
  
  admin_group_object_ids = [var.aad_group_id]

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
    vault = "52.138.106.19/32"
  }
}