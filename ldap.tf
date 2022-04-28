resource "kubernetes_secret" "dali_hpcc_admin" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.ldap_enabled ? 1 : 0

  metadata {
    name      = "dali-hpcc-admin-secret"
    namespace = var.namespace.name
    labels = {
      name = "dali-hpcc-admin-secret"
    }
  }
  data = {
    password = var.ldap_config.dali.hpcc_admin_password
    username = var.ldap_config.dali.hpcc_admin_username
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "dali_ldap_admin" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.ldap_enabled ? 1 : 0

  metadata {
    name      = "dali-ldap-admin-secret"
    namespace = var.namespace.name
    labels = {
      name = "dali-ldap-admin-secret"
    }
  }
  data = {
    password = var.ldap_config.dali.ldap_admin_password
    username = var.ldap_config.dali.ldap_admin_username
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "esp_ldap_admin" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = local.ldap_enabled ? 1 : 0

  metadata {
    name      = "esp-ldap-admin-secret"
    namespace = var.namespace.name
    labels = {
      name = "esp-ldap-admin-secret"
    }
  }
  data = {
    password = var.ldap_config.esp.ldap_admin_password
    username = var.ldap_config.esp.ldap_admin_username
  }
  type = "kubernetes.io/basic-auth"
}