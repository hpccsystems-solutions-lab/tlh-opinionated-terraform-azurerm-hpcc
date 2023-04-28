# K8s CronJob to scan for Remote Certificates

resource "kubernetes_cron_job" "scan_certificates_job" {

  depends_on = [
    kubernetes_cluster_role.cluster_role,
    kubernetes_service_account.service_account,
    kubernetes_cluster_role_binding_v1.cluster_role
  ]
  metadata {
    name = "hpcc-scan-certificates-cronjob"
    namespace = var.namespace
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = var.schedule
    starting_deadline_seconds     = var.starting_deadline_seconds
    successful_jobs_history_limit = var.successful_jobs_history_limit
    job_template {
      spec {
        backoff_limit              = var.backoff_limit
        ttl_seconds_after_finished = var.ttl_seconds_after_finished

        template {
          spec {
            container {
              name    = var.container_name
              image   = var.container_image
              command = var.container_startup_command
            }
          }
        }
      }
    }
  }
}


# Service Account to Access Secrets in K8s Namespace

resource "kubernetes_service_account" "service_account" {
  metadata {
    name = "hpcc-certificates-share-service-account"
    namespace = var.namespace
  }
}

# Cluster Role for Service Account

resource "kubernetes_cluster_role" "cluster_role" {
  metadata {
    name = "hpcc-certificates-share-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

# Binding Cluster Role to Service Account

resource "kubernetes_cluster_role_binding_v1" "role_binding" {
  metadata {
    name = "hpcc-certificates-share-cluster-rolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "certificates-cron-secret-reader"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.service_account.name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_service_account.service_account
  ]
}