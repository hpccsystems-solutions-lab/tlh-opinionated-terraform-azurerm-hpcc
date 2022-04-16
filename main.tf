resource "kubernetes_namespace" "default" {
  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

module "node_tuning" {
  source = "./modules/node_tuning"

  count = var.enable_node_tuning ? 1 : 0

  containers              = var.node_tuning_containers
  container_registry_auth = var.node_tuning_container_registry_auth
}

resource "helm_release" "hpcc" {
  depends_on = [
    kubernetes_persistent_volume_claim.blob_nfs,
    kubernetes_persistent_volume_claim.hpc_cache,
    kubernetes_persistent_volume_claim.spill,
    kubernetes_secret.hpcc_container_registry_auth,
    module.node_tuning
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

resource "local_file" "test" {
  content  = yamlencode(local.helm_chart_values)
  filename = "/Users/tmiller/git-repos/tfe/terraform-azurerm-hpcc/examples/shortcut/hpcc.yaml"
}