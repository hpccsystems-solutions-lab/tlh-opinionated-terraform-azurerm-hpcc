resource "kubernetes_secret" "container_registry_auth" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.create_registry_auth_secret ? 1 : 0

  metadata {
    name      = "container-registry-auth"
    namespace = var.namespace.name
    labels = {
      name = "container-registry-auth"
    }
  }
  data = {
    ".dockerconfigjson" = <<DOCKER
      { 
        "auths" :{ 
          "${var.container_registry.image_root}": {
              "username":"${var.container_registry.username}",
              "password":"${var.container_registry.password}",
              "auth": "${base64encode("${var.container_registry.username}:${var.container_registry.password}")}"
      }
   }
}
DOCKER
  }
  type = "kubernetes.io/dockerconfigjson"
}