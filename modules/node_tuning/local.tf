locals {
  auth_urls = toset([regex("^(.*)/", var.containers.busybox).0, regex("^(.*)/", var.containers.debian).0])

  create_kubernetes_secret = var.container_registry_auth == null ? false : true
}