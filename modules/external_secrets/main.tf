resource "kubernetes_namespace" "external-secrets" {
  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

resource "helm_release" "external-secret-operator" {

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.5.9"
  namespace  = var.namespace.name

  values = [
    yamlencode(local.yaml.external-secret-operator)
  ]

  depends_on = [
    kubernetes_namespace.external-secrets
  ]
}

# Creates a secret that holds the secret id for the vault

resource "kubernetes_secret" "secret_id" {

  count = var.vault_secret_id != "" ? 1 : 0

  metadata {
    name      = "external-secrets-approle-secret"
    namespace = var.namespace.name
  }

  data = {
    secretId = var.vault_secret_id
  }

  depends_on = [helm_release.external-secret-operator]
}

# Creates a secret that will store what is taken from vault


# resource "kubernetes_secret" "secrets" {

#   for_each = local.namespaces_set_all
#   metadata {
#     name      = "${each.value}-secrets"
#     namespace = each.value
#   }

#   data = {
#     extra = "dGhpcyBpcyBleHRyYSBmcm9tIGNyZWF0aW5nIHRoZSBzZWNyZXQ="
#   }

#   depends_on = [helm_release.external-secret-operator]
# }

# Creates a secretstore for each namespace listed in locals.tf varticals
# Secretstore connects to vault on a specified path 

# resource "kubectl_manifest" "secretstores" {

#   provider = kubectl.stable

#   for_each          = local.namespaces_set_all
#   yaml_body         = <<-EOF
#   apiVersion: external-secrets.io/v1beta1
#   kind: SecretStore
#   metadata:
#     name: ${each.value}-secretstore
#     namespace: ${each.value}
#   spec:
#     provider:
#       vault:
#         server: "https://vault.cluster.us-vault-prod.azure.lnrsg.io"
#         namespace: "dataengineering/dops/prod"
#         path: "${format("%s", split("-", each.value)[1])}"
#         version: "v2"
#         auth:
#           appRole:
#             path: "approle"
#             roleId: ${var.VAULT_ROLE_ID}
#             secretRef:
#               name: "vault-approle-secret"
#               key: "secretId"
#   EOF
#   server_side_apply = true

#   depends_on = [kubernetes_secret.secret_id, kubernetes_secret.secrets]
# }

# # Creates an externalsecret for each namespace listed in locals.tf verticals
# # Specifies the data to be pulled from vault
# resource "kubectl_manifest" "externalsecrets" {

#   provider = kubectl.stable

#   for_each = local.namespaces_set_all

#   yaml_body         = <<-EOF
#   apiVersion: external-secrets.io/v1beta1
#   kind: ExternalSecret
#   metadata:
#     name: ${each.value}-externalsecrets
#     namespace: ${each.value}
#   spec:
#     refreshInterval: "1m"
#     secretStoreRef:
#       name: ${each.value}-secretstore
#       kind: SecretStore
#     target:
#       name: ${each.value}-secrets
#     data:
#     - secretKey: DB_NAME
#       remoteRef:
#         key: /db
#         property: DB_NAME 
#     - secretKey: DB_PASS
#       remoteRef:
#         key: /db
#         property: DB_PASS
#     - secretKey: DB_PORT
#       remoteRef:
#         key: /db
#         property: DB_PORT
#     - secretKey: DB_SERVER
#       remoteRef:
#         key: /db
#         property: DB_SERVER
#     - secretKey: DB_USER
#       remoteRef:
#         key: /db
#         property: DB_USER
#     - secretKey: HPCC_PASS
#       remoteRef:
#         key: /hpcc
#         property: HPCC_PASS
#     - secretKey: HPCC_USER
#       remoteRef:
#         key: /hpcc
#         property: HPCC_USER
#     - secretKey: ORBIT_EDPW
#       remoteRef:
#         key: /orbit
#         property: ORBIT_EDPW
#     - secretKey: ORBIT_ENUN
#       remoteRef:
#         key: /orbit
#         property: ORBIT_ENUN
#     - secretKey: ORBIT_PASS
#       remoteRef:
#         key: /orbit
#         property: ORBIT_PASS
#     - secretKey: ORBIT_PRENPW
#       remoteRef:
#         key: /orbit
#         property: ORBIT_PRENPW
#     - secretKey: ORBIT_QAENPW
#       remoteRef:
#         key: /orbit
#         property: ORBIT_QAENPW
#     - secretKey: ORBIT_USER
#       remoteRef:
#         key: /orbit
#         property: ORBIT_USER
#   EOF
#   server_side_apply = true

#   depends_on = [kubectl_manifest.secretstores]
# }
