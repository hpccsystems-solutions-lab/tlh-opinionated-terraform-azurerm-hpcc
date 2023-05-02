# K8s Secret to store Cron Env Variables

resource "kubernetes_secret" "vault_sync_cron_env_settings" {

  count = length(var.cron_job_settings.container_environment_settings) > 0 ? 1 : 0

  metadata {
    name      = "hpcc-vault-sync-cron-env-settings"
    namespace = var.application_namespace
  }

  data = {
    SECRET_ID = var.cron_job_settings.container_environment_settings.VAULT_SECRET_ID
    ROLE_ID = var.cron_job_settings.container_environment_settings.VAULT_ROLE_ID
    URL = var.cron_job_settings.container_environment_settings.VAULT_URL
    VAULT_NAMESPACE = var.cron_job_settings.container_environment_settings.VAULT_NAMESPACE
  }

}




# Service Account to Access Secrets in K8s Namespace

resource "kubernetes_service_account" "service_account" {
  metadata {
    name = "hpcc-vault-sync-service-account"
    namespace = var.application_namespace
  }
}

# Cluster Role for Service Account

resource "kubernetes_cluster_role" "cluster_role" {
  metadata {
    name = "hpcc-certificates-vault-sync-cluster-role"
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
    name      = "hpcc-certificates-vault-sync-cluster-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "hpcc-vault-sync-service-account"
    namespace = var.application_namespace
  }

  depends_on = [
    kubernetes_service_account.service_account
  ]
}


# K8s CronJob to scan for Remote Certificates

resource "kubernetes_cron_job" "scan_certificates_job" {

  depends_on = [
    kubernetes_cluster_role.cluster_role,
    kubernetes_service_account.service_account,
    kubernetes_cluster_role_binding_v1.role_binding,
    kubernetes_secret.vault_sync_cron_env_settings
  ]
  metadata {
    name = "hpcc-vault-sync-cronjob"
    namespace = var.application_namespace
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = var.cron_job_settings.failed_jobs_history_limit
    schedule                      = var.cron_job_settings.schedule
    starting_deadline_seconds     = var.cron_job_settings.starting_deadline_seconds
    successful_jobs_history_limit = var.cron_job_settings.successful_jobs_history_limit
    job_template {
      metadata {}
      spec {
        backoff_limit              = var.cron_job_settings.backoff_limit
        ttl_seconds_after_finished = var.cron_job_settings.ttl_seconds_after_finished

        template {
          metadata {}
          spec {
            service_account_name = "hpcc-vault-sync-service-account"
            container {
              name    = var.cron_job_settings.container_name
              image   = local.container_image
              command = var.cron_job_settings.container_startup_command
              env {
                name = "ROLE_ID"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.vault_sync_cron_env_settings.0.metadata.0.name
                    key = "ROLE_ID"
                  }
                }
              }
              env {
                name = "SECRET_ID"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.vault_sync_cron_env_settings.0.metadata.0.name
                    key = "SECRET_ID"
                  }
                }
              }
              env {
                name = "URL"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.vault_sync_cron_env_settings.0.metadata.0.name
                    key = "URL"
                  }
                }
              }
              env {
                name = "VAULT_NAMESPACE"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.vault_sync_cron_env_settings.0.metadata.0.name
                    key = "VAULT_NAMESPACE"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}