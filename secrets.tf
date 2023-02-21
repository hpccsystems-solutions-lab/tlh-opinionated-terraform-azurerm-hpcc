resource "kubernetes_secret" "git_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  for_each = local.vault_enabled && var.vault_secrets.git_approle_secret != null ? var.vault_secrets.git_approle_secret : {}

  metadata {
    name      = each.value.secret_name
    namespace = var.namespace.name
    labels = {
      name = each.value.secret_name
    }
  }
  data = {
    secret_id = each.value.secret_value
  }
  type = "Opaque"
}

resource "kubernetes_secret" "ecl_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  for_each = local.vault_enabled && var.vault_secrets.ecl_approle_secret != null ? var.vault_secrets.ecl_approle_secret : {}

  metadata {
    name      = each.value.secret_name
    namespace = var.namespace.name
    labels = {
      name = each.value.secret_name
    }
  }
  data = {
    secret_id = each.value.secret_value
  }
  type = "Opaque"
}

resource "kubernetes_secret" "ecluser_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  for_each = local.vault_enabled && var.vault_secrets.ecluser_approle_secret != null ? var.vault_secrets.ecluser_approle_secret : {}


  metadata {
    name      = each.value.secret_name
    namespace = var.namespace.name
    labels = {
      name = each.value.secret_name
    }
  }
  data = {
    secret-id = each.value.secret_value
  }

  type = "Opaque"
}

resource "kubernetes_secret" "esp_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  for_each = local.vault_enabled && var.vault_secrets.esp_approle_secret != null ? var.vault_secrets.esp_approle_secret : {}


  metadata {
    name      = each.value.secret_name
    namespace = var.namespace.name
    labels = {
      name = each.value.secret_name
    }
  }
  data = {
    secret-id = each.value.secret_value
  }

  type = "Opaque"
}

