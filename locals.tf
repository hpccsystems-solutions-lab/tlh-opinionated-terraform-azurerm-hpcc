locals {
  # This may be passed in later as a variable.
  hpcc_pvc_config = {
    data = {
      path = "hpcc-data"
    }
    dali = {
      path = "dalistorage"
    }
    sasha = {
      path = "sashastorage"
    }
    dll = {
      path = "queries"
    }
    mydropzone = {
      path     = "mydropzone"
      category = "lz"
    }
  }

  hpcc_namespaces = [
    var.hpcc_namespace
  ]

  chart_values = {

    global = {
      image = {
        version    = var.hpcc_helm_version
        root       = var.hpcc_image_root
        name       = var.hpcc_image_name
        pullPolicy = "IfNotPresent"
      }
      visibilities = {
        cluster = {
          type = "ClusterIP"
        }
        local = {
          annotations = {
            "helm.sh/resource-policy"                                 = "keep"
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
          }
          type    = "LoadBalancer"
          ingress = []
        }
        global = {
          type    = "LoadBalancer"
          ingress = []
        }

      }
    }

    storage = {
      planes = [for k, v in kubernetes_persistent_volume_claim.hpcc_blob_pvcs :
        {
          name     = k
          pvc      = v.metadata.0.name
          prefix   = "/var/lib/HPCCSystems/${local.hpcc_pvc_config[k].path}"
          category = lookup(local.hpcc_pvc_config[k], "category", k)
        }
      ]
    }

    certificates = {
      enabled = false
      issuers = {
        local = {
          name = "letsencrypt-issuer"
          kind = "ClusterIssuer"
          spec = null
        }
      }
    }

    eclagent = [
      {
        name      = "hthor"
        replicas  = lookup(var.hpcc_replica_config, "eclagent", 1)
        maxActive = 4
      },
      {
        name      = "roxie-workunit"
        replicas  = lookup(var.hpcc_replica_config, "roxie-workunit", 1)
        maxActive = 4
      }
    ]

    eclccserver = [
      {
        name      = "myeclccserver"
        replicas  = lookup(var.hpcc_replica_config, "myeclccserver", 1)
        maxActive = 4
      }
    ]

    esp = [
      {
        name        = "eclwatch"
        application = "eclwatch"
        auth        = "none"
        replicas    = lookup(var.hpcc_replica_config, "eclwatch", 1)
        service = {
          port        = 8888
          servicePort = 8010
          visibility  = "local"
        }
      },
      {
        name        = "eclservices"
        application = "eclservices"
        auth        = "none"
        replicas    = lookup(var.hpcc_replica_config, "eclservices", 1)
        service = {
          servicePort = 8010
          visibility  = "cluster"
        }
      },
      {
        name        = "eclqueries"
        application = "eclqueries"
        auth        = "none"
        replicas    = lookup(var.hpcc_replica_config, "eclqueries", 1)
        service = {
          servicePort = 8002
          visibility  = "local"
        }
      },
      {
        name        = "esdl-sandbox"
        application = "esdl-sandbox"
        auth        = "none"
        replicas    = lookup(var.hpcc_replica_config, "esdl-sandbox", 1)
        service = {
          servicePort = 8899
          visibility  = "local"
        }
      },
      {
        name        = "sql2ecl"
        application = "sql2ecl"
        auth        = "none"
        replicas    = lookup(var.hpcc_replica_config, "sql2ecl", 1)
        service = {
          servicePort = 8510
          visibility  = "local"
        }
      }
    ]

    roxie = [
      {
        name     = "roxie"
        disabled = false
        prefix   = "roxie"
        services = [
          {
            name        = "roxie"
            servicePort = 9876
            listenQueue = 200
            numThreads  = 30
            visibility  = "local"
          }
        ]
        replicas       = lookup(var.hpcc_replica_config, "roxie", 2)
        numChannels    = 2
        serverReplicas = 0
        topoServer = {
          replicas = lookup(var.hpcc_replica_config, "roxie-toposerver", 1)
        }
      }
    ]

    thor = [
      {
        name       = "thor"
        prefix     = "thor"
        numWorkers = lookup(var.hpcc_replica_config, "thor-workers", 1)
        maxJobs    = 4
        maxGraphs  = 2
      }
    ]

    eclscheduler = [
      {
        name = "eclscheduler"
      }
    ]
  }

  # HPC Cache Roxie data
/*
  hpc_pvc_config = {
    data = {
      path = "hpcc-data"
    }
  }*/

  cache_values = {

    global = {
      image = {
        version    = var.hpcc_helm_version
        root       = var.hpcc_image_root
        name       = var.hpcc_image_name
        pullPolicy = "IfNotPresent"
      }
      visibilities = {
        cluster = {
          type = "ClusterIP"
        }
        local = {
          annotations = {
            "helm.sh/resource-policy"                                 = "keep"
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
          }
          type    = "LoadBalancer"
          ingress = []
        }
        global = {
          type    = "LoadBalancer"
          ingress = []
        }

      }
    }

    storage = {
      planes = [
        {
          name     = "data"
          pvc      = "hpcc-data"
          prefix   = "/var/lib/HPCCSystems/hpcc-data"
          category = "data"
        }
      ]
    }

    roxie = [
      {
        name     = "roxie"
        disabled = false
        prefix   = "roxie"
        services = [
          {
            name        = "roxie"
            servicePort = 9876
            listenQueue = 200
            numThreads  = 30
            visibility  = "local"
          }
        ]
        replicas       = lookup(var.hpcc_replica_config, "roxie", 2)
        numChannels    = 2
        serverReplicas = 0
        topoServer = {
          replicas = lookup(var.hpcc_replica_config, "roxie-toposerver", 1)
        }
      }
    ]
  }
}