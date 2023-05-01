resource "kubernetes_namespace" "external-secrets" {
  metadata {
    name   = var.helm_namespace.name
    labels = var.helm_namespace.labels
  }
}

resource "helm_release" "external-secret-operator" {

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.5.9"
  namespace  = var.helm_namespace.name

  values = [
    yamlencode(local.yaml.external-secret-operator)
  ]

  depends_on = [
    kubernetes_namespace.external-secrets
  ]
}

# Creates a secret that holds the secret id for the vault

resource "kubernetes_secret" "secret_id" {

  count = length(var.vault_secret_id) > 0 ? 1 : 0

  metadata {
    name      = var.vault_secret_id.name
    namespace = var.application_namespace
  }

  data = {
    secretId = var.vault_secret_id.secret_value
  }

  depends_on = [helm_release.external-secret-operator]
}

# Creates a secret that will store what is taken from vault


# resource "kubernetes_secret" "init-secrets" {

#   metadata {
#     name      = "smallscaletest-dev-remote-secret-insuranceprod"
#     namespace = "hpcc"
#   }

#   data = {
#     extra = "dGhpcyBpcyBleHRyYSBmcm9tIGNyZWF0aW5nIHRoZSBzZWNyZXQ="
#   }

#   depends_on = [helm_release.external-secret-operator]
# }

# resource "kubernetes_secret" "init-secrets-two" {

#   metadata {
#     name      = "smallscaletest-dev-remote-secrets-dopsprod"
#     namespace = "hpcc"
#   }

#   data = {
#     extra = "dGhpcyBpcyBleHRyYSBmcm9tIGNyZWF0aW5nIHRoZSBzZWNyZXQ="
#   }

#   depends_on = [helm_release.external-secret-operator]
# }

# # Creates a secretstore for each namespace listed in locals.tf varticals
# # Secretstore connects to vault on a specified path 

# resource "kubectl_manifest" "secretstores" {

#   yaml_body         = <<-EOF
#   apiVersion: external-secrets.io/v1beta1
#   kind: SecretStore
#   metadata:
#     name: smallscaletest-dev-secretstore
#     namespace: hpcc
#   spec:
#     provider:
#       vault:
#         server: "https://vault.cluster.us-vault-prod.azure.lnrsg.io"
#         namespace: "hpccsystems/hpccsystems_test"
#         path: "smallscaletest_dev/"
#         version: "v2"
#         auth:
#           appRole:
#             path: "approle"
#             roleId: "403cb692-00ea-0524-c6a3-dd4695810704"
#             secretRef:
#               name: "external-secrets-approle-secret"
#               key: "secretId"
#   EOF
#   server_side_apply = true

#   depends_on = [kubernetes_secret.init-secrets, kubernetes_secret.secret_id]
# }

# # # Creates an externalsecret for each namespace listed in locals.tf verticals
# # # Specifies the data to be pulled from vault

# # Insurance External Secret 

# resource "kubectl_manifest" "externalsecrets" {
#   yaml_body         = <<-EOF
#   apiVersion: external-secrets.io/v1beta1
#   kind: ExternalSecret
#   metadata:
#     name: smallscaletest-dev-externalsecrets-insuranceprod
#     namespace: hpcc
#   spec:
#     refreshInterval: "1m"
#     secretStoreRef:
#       name: smallscaletest-dev-secretstore
#       kind: SecretStore
#     target:
#       name: "smallscaletest-dev-remote-secret-insuranceprod"
#     data:
#     - secretKey: ca.crt
#       remoteRef:
#         key: client-remote-dfs-dfs-hpcc-insuranceprod-tls
#         property: ca.crt
#     - secretKey: tls.key
#       remoteRef:
#         key: client-remote-dfs-dfs-hpcc-insuranceprod-tls
#         property: tls.key
#     - secretKey: tls.crt
#       remoteRef:
#         key: client-remote-dfs-dfs-hpcc-insuranceprod-tls
#         property: tls.crt                
#   EOF
#   server_side_apply = true

#   depends_on = [kubectl_manifest.secretstores]
# }


# resource "kubectl_manifest" "externalsecrets_two" {
#   yaml_body         = <<-EOF
#   apiVersion: external-secrets.io/v1beta1
#   kind: ExternalSecret
#   metadata:
#     name: smallscaletest-dev-externalsecrets-dopsprod
#     namespace: hpcc
#   spec:
#     refreshInterval: "1m"
#     secretStoreRef:
#       name: smallscaletest-dev-secretstore
#       kind: SecretStore
#     target:
#       name: "smallscaletest-dev-remote-secrets-dopsprod"
#     data:
#     - secretKey: ca.crt
#       remoteRef:
#         key: client-remote-dfs-dfs-hpcc-dopsprod-tls
#         property: ca.crt
#     - secretKey: tls.key
#       remoteRef:
#         key: client-remote-dfs-dfs-hpcc-dopsprod-tls
#         property: tls.key
#     - secretKey: tls.crt
#       remoteRef:
#         key: client-remote-dfs-dfs-hpcc-dopsprod-tls
#         property: tls.crt                
#   EOF
#   server_side_apply = true

#   depends_on = [kubectl_manifest.secretstores]
# }
