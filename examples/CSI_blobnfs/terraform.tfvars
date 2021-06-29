external_dns_zones = {
    names = ["infrastructuresandbox.us.lnrisk.io"]
    resource_group_name = "rg-iog-sandbox-eastus2-lnriskio"
}

cert_manager_dns_zones = {
    "infrastructuresandbox.us.lnrisk.io" = "rg-iog-sandbox-eastus2-lnriskio"
}

smtp_host = ""
smtp_from = "James.Hodnett@lexisnexisrisk.com"
alerts_mailto = "James.Hodnett@lexisnexisrisk.com"

namespace = "hpcc-demo"
