resource "kubernetes_secret" "system_secrets" {
  for_each = var.system_secrets

  metadata {
    name = each.value.name
    labels = {
      name = each.value.name
    }
  }

  data = {
    value = each.value.value
  }

  type = "kubernetes.io/generic"
}