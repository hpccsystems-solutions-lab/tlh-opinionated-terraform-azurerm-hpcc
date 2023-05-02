resource "kubernetes_namespace" "default" {
  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

module "node_tuning" {
  source = "./modules/node_tuning"

  count = var.enable_node_tuning ? 1 : 0

  containers = local.acr_default

  container_registry_auth = var.node_tuning_container_registry_auth

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
  helm_namespace  = var.external_secrets.namespace
  vault_secret_id = var.external_secrets.vault_secret_id
  secret_stores = var.external_secrets.secret_stores
  secrets   = var.external_secrets.secrets

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
    module.node_tuning,
    module.certificates,
    module.external_secrets,
  ]

  timeout = var.helm_chart_timeout

  name       = "hpcc"
  namespace  = var.namespace.name
  chart      = "hpcc"
  repository = "https://hpcc-systems.github.io/helm-chart"
  version    = var.helm_chart_version
  values = [
    yamlencode(local.helm_chart_values),
    var.helm_chart_overrides
  ]
}