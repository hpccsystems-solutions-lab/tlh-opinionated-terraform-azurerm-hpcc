resource "kubernetes_secret" "git_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.vault_enabled && var.system_secrets.git_approle_secret != null ? 1 : 0

  metadata {
    name      = "my-git-approle-secret"
    namespace = var.namespace.name
    labels = {
      name = "my-git-approle-secret"
    }
  }
  data = {
    secret_id = var.system_secrets.git_approle_secret
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "ecl_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.vault_enabled && var.system_secrets.ecl_approle_secret != null ? 1 : 0


  metadata {
    name      = "my-ecl-approle-secret"
    namespace = var.namespace.name
    labels = {
      name = "my-ecl-approle-secret"
    }
  }
  data = {
    secret_id = var.system_secrets.ecl_approle_secret
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "eclUser_approle_secret_id" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.vault_enabled && var.system_secrets.eclUser_approle_secret != null ? 1 : 0


  metadata {
    name      = "eclUser-approle-secret"
    namespace = var.namespace.name
    labels = {
      name = "eclUser-approle-secret"
    }
  }
  data = {
    secret_id = var.system_secrets.eclUser_approle_secret
  }
  type = "kubernetes.io/basic-auth"
}