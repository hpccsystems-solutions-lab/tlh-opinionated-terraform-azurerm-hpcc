locals {
  account_code = "us-prctrox-dev"

  cluster_name = "us-dev-aks-000"

  cluster_version = "1.21"

  dns_resource_group = "app-dns-prod-eastus2"

  internal_domain = "us-prctrox-dev.azure.lnrsg.io"

  cluster_name_short = trimprefix(local.cluster_name, "${local.account_code}-")
  azuread_clusterrole_map = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }

  grafana_admin_password  = random_string.random.result
  smtp_host               = "smtp.lexisnexisrisk.com:25"
  smtp_from               = "ioa-eks-1@lexisnexisrisk.com"
  alert_manager_routes    = []
  alert_manager_recievers = []

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