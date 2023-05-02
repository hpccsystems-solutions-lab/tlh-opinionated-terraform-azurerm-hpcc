resource "kubernetes_namespace" "external_secrets_namespace" {
  metadata {
    name   = var.helm_namespace.name
    labels = var.helm_namespace.labels
  }
}

resource "helm_release" "external_secrets_helm_release" {

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.8.1"
  namespace  = var.helm_namespace.name

  values = [
    yamlencode(local.yaml.external-secret-operator)
  ]

  depends_on = [
    kubernetes_namespace.external_secrets_namespace
  ]
}

# Creates a secret that holds the secret id for the vault

resource "kubernetes_secret" "external_secrets_approle_secret_id" {

  count = length(var.vault_secret_id) > 0 ? 1 : 0

  metadata {
    name      = var.vault_secret_id.name
    namespace = var.application_namespace
  }

  data = {
    secretId = var.vault_secret_id.secret_value
  }

  depends_on = [helm_release.external_secrets_helm_release]
}

# Secret Stores which will authenticate to the Vault and Pull down the KV Secrets
# # Creates a secretstore for each Vault Namespace coming from the secret_stores variable.
# # Secretstore connects to vault on a specified path 

resource "kubectl_manifest" "secretstores" {

  for_each = length(var.secret_stores) > 0 ? var.secret_stores : {}

  yaml_body         = <<-EOF
  apiVersion: external-secrets.io/v1beta1
  kind: SecretStore
  metadata:
    name: ${each.value.secret_store_name}
    namespace: ${var.application_namespace}
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
              name: ${kubernetes_secret.external_secrets_approle_secret_id.0.metadata.0.name}
              key: "secretId"
  EOF
  server_side_apply = true

  depends_on = [helm_release.external_secrets_helm_release, kubernetes_secret.external_secrets_approle_secret_id]
}

# Creates a secret that will store what is pulled from vault. The Target K8s Secret, initializing with dummy value.


resource "kubernetes_secret" "target_secrets" {

  for_each = length(var.secrets) > 0 ? var.secrets : {}

  metadata {
    name      = each.value.target_secret_name
    namespace = var.application_namespace
  }

  data = {
    extra = "dGhpcyBpcyBleHRyYSBmcm9tIGNyZWF0aW5nIHRoZSBzZWNyZXQ="
  }

  depends_on = [helm_release.external_secrets_helm_release, kubectl_manifest.secretstores]
}




# # # Creates an externalsecret object for each KV secret to be pulled from the Vault
# # # Specifies the data to be pulled from vault


resource "kubectl_manifest" "externalsecrets_object" {

  for_each = length(var.secrets) > 0 ? var.secrets : {}

  yaml_body         = <<-EOF
  apiVersion: external-secrets.io/v1beta1
  kind: ExternalSecret
  metadata:
    name: ${each.value.target_secret_name}-es-object
    namespace: ${var.application_namespace}
  spec:
    refreshInterval: "1m"
    secretStoreRef:
      name: ${each.value.secret_store_name}
      kind: SecretStore
    target:
      name: ${each.value.target_secret_name}
    data:
    - secretKey: ca.crt
      remoteRef:
        key: ${each.value.remote_secret_name}
        property: ca.crt
    - secretKey: tls.key
      remoteRef:
        key: ${each.value.remote_secret_name}
        property: tls.key
    - secretKey: tls.crt
      remoteRef:
        key: ${each.value.remote_secret_name}
        property: tls.crt                
  EOF
  server_side_apply = true

  depends_on = [helm_release.external_secrets_helm_release, kubectl_manifest.secretstores, kubernetes_secret.target_secrets]
}

