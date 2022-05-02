resource "kubernetes_network_policy" "eclwatch" {
  metadata {
    name      = "eclwatch"
    namespace = var.namespace.name
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