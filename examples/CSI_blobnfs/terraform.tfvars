config = {
    external_dns = {
        zones = ["infrastructuresandbox.us.lnrisk.io"]
        resource_group_name = "rg-iog-sandbox-eastus2-lnriskio"
    }
    cert_manager = {
        letsencrypt_environment = "staging"
        dns_zones = {
            "infrastructuresandbox.us.lnrisk.io" = "rg-iog-sandbox-eastus2-lnriskio"
        }
    }

}
smtp_host = ""
smtp_from = "James.Hodnett@lexisnexisrisk.com"
alerts_mailto = "James.Hodnett@lexisnexisrisk.com"

namespace = "hpcc-demo"

hpcc_config = {
    storage = {
        data = {
            volume_size = "10Gi"
            path_prefix = "/var/lib/HPCCSystems/hpcc-data"
            pvc_name    =  "pvc-blob-data-nfs"
        }
        dali = {
            volume_size = "1Gi"
            path_prefix = "/var/lib/HPCCSystems/dalistorage"
            pvc_name    =  "pvc-blob-dali-nfs"
        }
        sasha = {
            volume_size = "1Gi"
            path_prefix = "/var/lib/HPCCSystems/sashastorage"
            pvc_name    =  "pvc-blob-sasha-nfs"
        }
        dll = {
            volume_size = "1Gi"
            path_prefix = "/var/lib/HPCCSystems/queries"
            pvc_name    =  "pvc-blob-dll-nfs"
        }
    }
}