
resource "helm_release" "hpcc_storage" {
  name       = "${var.name}-storage"
  namespace  = var.namespace
  create_namespace = var.create_namespace
  chart      = "./helm_charts/hpcc-azurefile"
  values = var.hpcc_storage_values
}


resource "helm_release" "hpcc" {
  depends_on = [helm_release.hpcc_storage]
  name       = var.name
  namespace  = var.namespace
  create_namespace = var.create_namespace
  chart      = "hpcc"
  repository = "https://hpcc-systems.github.io/helm-chart"
  version = var.hpcc_helm_version
  values = var.hpcc_system_values
}