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
  version    = "0.8.1"
  namespace  = var.helm_namespace.name

  values = [
    yamlencode(local.yaml.external-secret-operator)
  ]

  depends_on = [
    kubernetes_namespace.external-secrets
  ]
}

# Creates a secret that holds the secret id for the vault

resource "kubernetes_secret" "approle_secret_id" {

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

# Secret Stores which will authenticate to the Vault and Pull down the KV Secrets
# # Creates a secretstore for each Vault Namespace coming from the secret_stores variable.
# # Secretstore connects to vault on a specified path 

resource "kubectl_manifest" "secretstores" {

  for_each = var.secret_stores

  yaml_body         = <<-EOF
  apiVersion: external-secrets.io/v1beta1
  kind: SecretStore
  metadata:
    name: ${each.value.secret_store_name}
    namespace: ${each.value.secret_store_namespace}
  spec:
    provider:
      vault:
        server: ${each.value.vault_url}
        namespace: ${each.value.vault_namespace}
        path: ${each.value.vault_kv_path}
        version: "v2"
        auth:
          appRole:
            path: "approle"
            roleId: ${each.value.approle_role_id}
            secretRef:
              name: ${kubernetes_secret.approle_secret_id.0.metadata.0.name}
              key: "secretId"
  EOF
  server_side_apply = true

  depends_on = [kubernetes_secret.approle_secret_id]
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
