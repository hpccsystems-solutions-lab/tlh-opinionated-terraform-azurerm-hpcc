resource "helm_release" "csi_driver" {
  depends_on = [
    kubernetes_namespace.default,
    module.data_storage
  ]

  count = var.install_blob_csi_driver ? 1 : 0

  chart      = "blob-csi-driver"
  name       = "blob-csi-driver"
  namespace  = local.blob_csi_driver.namespace.name
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts"
  version    = local.blob_csi_driver.chart_version
}