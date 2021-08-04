smtp_host     = ""
smtp_from     = "James.Hodnett@lexisnexisrisk.com"
alerts_mailto = "James.Hodnett@lexisnexisrisk.com"

hpcc_helm_version = "8.2.6-rc1"

namespaces =  [
  "hpcc-demo",
  "blob-csi-driver",
  "elasticsearch"
]

hpcc_storage = {
  data       = "10Gi"
  dali       = "1Gi"
  dll        = "1Gi"
  sasha      = "1Gi"
  mydropzone = "1Gi"
}

