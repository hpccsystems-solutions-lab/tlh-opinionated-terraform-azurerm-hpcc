
address_space = ["10.1.0.0/22"]

core_services_config = {
  alertmanager = {
    smtp_host = "smtp.foo.bar"
    smtp_from = "Akhila.Damera@lexisnexisrisk.com"
    receivers = [{ name = "alerts", email_configs = [{ to = "Akhila.Damera@lexisnexisrisk.com", require_tls = false }] }]
  }

  ingress_internal_core = {
    domain = "us-infrastructure-dev.azure.lnrsg.io"
  }

  external_dns = {
    zones               = ["us-infrastructure-dev.azure.lnrsg.io"]
    resource_group_name = "app-dns-prod-eastus2"
  }
  cert_manager = {
    letsencrypt_environment = "staging"
    letsencrypt_email       = "Akhila.Damera@lexisnexisrisk.com"
    dns_zones = {
      "us-infrastructure-dev.azure.lnrsg.io" = "app-dns-prod-eastus2"
    }
    azure_environment = "AzurePublicCloud"
  }
}

azuread_clusterrole_map = {
  cluster_admin_users = {
    "DameAk01_risk.regn.net" = "ebb1bfeb-2803-42e8-b75c-32b0d6be1d0e"
    "us-infrastructure-dev-owners" = "f2e5d379-75f8-4d12-9cbf-20663822ba93"
  }
  cluster_view_users   = {}
  standard_view_users  = {}
  standard_view_groups = {}
}

api_server_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}

storage_account_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}

private_cidrs = ["10.1.3.0/25"]
public_cidrs  = ["10.1.3.128/25"]

hpcc_storage_sizes = {
  data       = "10Gi"
  dali       = "1Gi"
  dll        = "1Gi"
  sasha      = "1Gi"
  mydropzone = "1Gi"
}