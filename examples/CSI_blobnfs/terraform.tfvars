
address_space = ["10.1.0.0/22"]

core_services_config = {
  alertmanager = {
    smtp_host = "smtp.foo.bar"
    smtp_from = "James.Hodnett@lexisnexisrisk.com"
    receivers = [{ name = "alerts", email_configs = [{ to = "James.Hodnett@lexisnexisrisk.com", require_tls = false }] }]
  }

  ingress_internal_core = {
    domain = "infrastructure-sandbox.us.lnrisk.io"
  }

  external_dns = {
    zones               = ["infrastructure-sandbox.us.lnrisk.io"]
    resource_group_name = "rg-iog-sandbox-eastus2-lnriskio"
  }
  cert_manager = {
    letsencrypt_environment = "staging"
    letsencrypt_email       = "James.Hodnett@lexisnexisrisk.com"
    dns_zones = {
      "infrastructure-sandbox.us.lnrisk.io" = "rg-iog-sandbox-eastus2-lnriskio"
    }
  }
}

azuread_clusterrole_map = {
  cluster_admin_users = {
    "hodnja01@risk.regn.net" = "fe33802a-25bf-4847-aa4e-85357dc91d8e"
    iog_dev_write            = "8d47c834-0c73-4467-9b79-783c1692c4e5"
  }
  cluster_view_users   = {}
  standard_view_users  = {}
  standard_view_groups = {}
}

api_server_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
}

private_cidrs = ["10.1.3.0/25"]
public_cidrs  = ["10.1.3.128/25"]

hpcc_storage = {
  data       = "10Gi"
  dali       = "1Gi"
  dll        = "1Gi"
  sasha      = "1Gi"
  mydropzone = "1Gi"
}