
resource "helm_release" "hpcc" {
  depends_on = [helm_release.hpcc_storage]
  name       = var.name
  namespace  = var.namespace
  create_namespace = var.create_namespace
  chart      = "hpcc"
  repository = "https://hpcc-systems.github.io/helm-chart"
  version = var.hpcc_helm_version
  values = [templatefile("${path.module}/hpcc_systems_values.yaml.tpl", var.hpcc_config)]
}