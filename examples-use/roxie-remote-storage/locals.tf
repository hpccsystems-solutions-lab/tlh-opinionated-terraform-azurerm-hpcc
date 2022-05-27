locals {
  core_services_config = {
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
    alertmanager = {
      smtp_host = "smtp.lexisnexisrisk.com:25"
      smtp_from = "HPCCOps@lexisnexisrisk.com"
      receivers = []
    }
    external_dns = {
      zones               = [local.zone_name]
      resource_group_name = "app-dns-prod-eastus2"
    }
    cert_manager = {
      letsencrypt_environment = "staging"
      letsencrypt_email       = null
      dns_zones = {
        "us-prbooleanrox-dev.azure.lnrsg.io" = "app-dns-prod-eastus2"
      }
    }

    ingress_internal_core = {
      domain = "us-prbooleanrox-dev.azure.lnrsg.io"
    }
    ingress_core_internal = {
      domain = "us-prbooleanrox-dev.azure.lnrsg.io"
    }
  }
  zone_name = "us-prbooleanrox-dev.azure.lnrsg.io"
}

