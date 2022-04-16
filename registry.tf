resource "kubernetes_secret" "hpcc_container_registry_auth" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.create_hpcc_registry_auth_secret ? 1 : 0

  metadata {
    name      = "container-registry-auth"
    namespace = var.namespace.name
    labels = {
      name = "container-registry-auth"
    }
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.hpcc_container.image_root}" = {
          auth = base64encode("${var.hpcc_container_registry_auth.username}:${var.hpcc_container_registry_auth.password}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
}