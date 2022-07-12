resource "kubernetes_network_policy" "eclwatch" {
  depends_on = [
    kubernetes_namespace.default
  ]

  metadata {
    name      = "eclwatch"
    namespace = var.namespace.name
    annotations = {
      "app.kubernetes.io/managed-by" = "Helm"
      "meta.helm.sh/release-name" = "hpcc"
      "meta.helm.sh/release-namespace" = "hpcc"
    }
  }

  spec {
    pod_selector {
      match_labels = {
        server = "eclwatch"
      }
    }

    ingress {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "eclqueries" {
  depends_on = [
    kubernetes_namespace.default
  ]

  metadata {
    name      = "eclqueries"
    namespace = var.namespace.name
  }

  spec {
    pod_selector {
      match_labels = {
        server = "eclqueries"
      }
    }

    ingress {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "esdl_sandbox" {
  depends_on = [
    kubernetes_namespace.default
  ]

  metadata {
    name      = "esdl-sandbox"
    namespace = var.namespace.name
  }

  spec {
    pod_selector {
      match_labels = {
        server = "esdl-sandbox"
      }
    }

    ingress {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "roxie" {
  depends_on = [
    kubernetes_namespace.default
  ]

  for_each = local.enabled_roxie_configs

  metadata {
    name      = each.value.name
    namespace = var.namespace.name
  }

  spec {
    pod_selector {
      match_labels = {
        server = "${each.value.name}-server"
      }
    }

    ingress {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "sql2ecl" {
  depends_on = [
    kubernetes_namespace.default
  ]

  metadata {
    name      = "sql2ecl"
    namespace = var.namespace.name
  }

  spec {
    pod_selector {
      match_labels = {
        server = "sql2ecl"
      }
    }

    ingress {}

    policy_types = ["Ingress"]
  }
}