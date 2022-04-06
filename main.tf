resource "kubernetes_namespace" "default" {
  for_each = local.namespaces

  metadata {
    name   = each.value.name
    labels = each.value.labels
  }
}

resource "helm_release" "hpcc" {
  depends_on = [
    kubernetes_persistent_volume_claim.blob_nfs,
    kubernetes_persistent_volume_claim.hpc_cache,
    kubernetes_persistent_volume_claim.spill,
    kubernetes_secret.container_registry_auth
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