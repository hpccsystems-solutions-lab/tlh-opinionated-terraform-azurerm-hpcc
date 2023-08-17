resource "kubernetes_namespace" "default" {
  count = var.namespace.create_namespace ? 1 : 0
  
  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

module "certificates" {
  source          = "./modules/certificates"
  internal_domain = var.internal_domain
  namespace       = var.namespace.name

  depends_on = [kubernetes_namespace.default]
}

module "external_secrets" {
  source = "./modules/es_module"

  depends_on = [kubernetes_namespace.default]

  count = var.external_secrets.enabled ? 1 : 0

  application_namespace = var.namespace.name
  helm_namespace        = var.external_secrets.namespace
  vault_secret_id       = var.external_secrets.vault_secret_id
  secret_stores         = var.external_secrets.secret_stores
  secrets               = var.external_secrets.secrets
}

resource "helm_release" "hpcc" {
  depends_on = [
    kubernetes_namespace.default,
    kubernetes_persistent_volume_claim.azurefiles,
    kubernetes_persistent_volume_claim.blob_nfs,
    kubernetes_persistent_volume_claim.hpc_cache,
    kubernetes_persistent_volume_claim.spill,
    kubernetes_secret.hpcc_container_registry_auth,
    kubernetes_secret.dali_hpcc_admin,
    kubernetes_secret.dali_ldap_admin,
    kubernetes_secret.esp_ldap_admin,
    kubernetes_secret.git_approle_secret_id,
    kubernetes_secret.ecl_approle_secret_id,
    kubernetes_secret.ecluser_approle_secret_id,
    kubernetes_secret.esp_approle_secret_id,
    module.certificates,
    module.external_secrets,
  ]

  timeout = var.helm_chart_timeout

  name       = "hpcc"
  namespace  = var.namespace.name
  chart      = var.hpcc_container.custom_chart_version == null ? "hpcc" : var.hpcc_container.custom_chart_version
  repository = var.hpcc_container.custom_chart_version == null ? "https://hpcc-systems.github.io/helm-chart" : null
  version    = var.hpcc_container.version != "latest" ? var.hpcc_container.version : null
  values = concat([
    yamlencode(local.helm_chart_values)],
    concat([for v in var.helm_chart_files_overrides : file(v)]),
    var.helm_chart_strings_overrides
  )
}

# Deploy Vault Sync Cron Job once HPCC Helm Release is complete with ESP Remote Client Secrets Generated

# module "vault_sync_cron_module" {
#   source = "./modules/vault_sync"

#   depends_on = [
#     kubernetes_namespace.default,
#     helm_release.hpcc
#   ]

#   count = var.vault_sync_cron_job.enabled ? 1 : 0

#   cron_job_settings     = var.vault_sync_cron_job.cron_job_settings
#   productname           = var.productname
#   environment           = var.environment
#   application_namespace = var.namespace.name

# } 
