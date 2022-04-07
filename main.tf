resource "kubernetes_namespace" "default" {
  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

module "node_tuning" {
  source = "./modules/node_tuning"

  count = var.enable_node_tuning ? 1 : 0
}

resource "helm_release" "hpcc" {
  depends_on = [
    kubernetes_persistent_volume_claim.blob_nfs,
    kubernetes_persistent_volume_claim.hpc_cache,
    kubernetes_persistent_volume_claim.spill,
    kubernetes_secret.container_registry_auth,
    module.node_tuning
  ]

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