resource "kubernetes_namespace" "default" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

resource "helm_release" "csi_driver" {
  depends_on = [
    kubernetes_namespace.default
  ]

  chart      = "blob-csi-driver"
  name       = "blob-csi-driver"
  namespace  = var.namespace.name
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version    = var.helm_chart_version
}