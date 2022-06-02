locals {
  auth_urls = toset([regex("^(.*)/", var.containers.busybox).0, regex("^(.*)/", var.containers.debian).0])

  create_kubernetes_secret = var.container_registry_auth == null ? false : true

  acr_defaults = {
    busybox = format("us%s%sacr.azurecr.io/hpccoperations/busybox:latest", var.productname, var.environment)
    debian = format("us%s%sacr.azurecr.io/hpccoperations/debian:bullseye-slim", var.productname, var.environment)
  }
}