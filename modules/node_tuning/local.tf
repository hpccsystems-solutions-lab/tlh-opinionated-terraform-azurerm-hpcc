locals {
  auth_urls = local.create_kubernetes_secret ? toset([regex("^(.*)/", var.containers.busybox).0, regex("^(.*)/", var.containers.debian).0]) : null

  create_kubernetes_secret = var.container_registry_auth == null ? false : true

}
