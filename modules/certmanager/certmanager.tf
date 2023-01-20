###local_issuer####
######
resource "kubectl_manifest" "local_issuer" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
   name: "hpcc-local-issuer"
   namespace: ${var.namespace}
  labels: 
   app.kubernetes.io/managed-by: "Helm"
  annotations:
   meta.helm.sh/release-name: "hpcc"
   meta.helm.sh/release-namespace: ${var.namespace}
  spec:
    selfSigned: {}
  EOF
  server_side_apply = true

}
resource "kubectl_manifest" "local_cert_issuer" {

yaml_body         = <<-EOF
 apiVersion: cert-manager.io/v1
 kind: Certificate
 metadata:
  name: "hpcc-local-issuer"
  namespace: ${var.namespace}
 spec:
  secretName: "hpcc-local-issuer-key-pair"
  subject:
   organizations:
   - HPCC Systems
   countries:
   - US
   organizationalUnits:
   - HPCC Example
   localities:
   - Alpharetta
   provinces:
   - Georgia
  isCA: true
  issuerRef:
    name: "hpcc-local-issuer"
    kind: Issuer
  dnsNames:
  - ${var.internal_domain}
  EOF
  server_side_apply = true

  depends_on = [kubectl_manifest.local_issuer]
}

# resource "kubectl_manifest" "local_secret" {

#   yaml_body         = <<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-local-issuer
#     namespace: ${var.namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-local-issuer-key-pair"
#   EOF
#   server_side_apply = true

#   depends_on = [kubectl_manifest.local_cert_issuer]
# }

# ###############remote########################
resource "kubectl_manifest" "remote_issuer" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
   name: "hpcc-remote-issuer"
   namespace: ${var.namespace}
  labels: 
    app.kubernetes.io/managed-by: "Helm"
  annotations:
    meta.helm.sh/release-name: "hpcc"
    meta.helm.sh/release-namespace: ${var.namespace}
  spec:
    selfSigned: {}
  EOF
  server_side_apply = true
}
resource "kubectl_manifest" "remote_cert_issuer" {

  yaml_body         = <<-EOF
 apiVersion: cert-manager.io/v1
 kind: Certificate
 metadata:
  name: "hpcc-remote-issuer"
  namespace: ${var.namespace}
 spec:
  secretName: "hpcc-remote-issuer-key-pair"
  subject:
   organizations:
   - HPCC Systems
   countries:
   - US
   organizationalUnits:
   - HPCC Example
   localities:
   - Alpharetta
   provinces:
   - Georgia
  isCA: true
  issuerRef:
    name: "hpcc-remote-issuer"
    kind: Issuer
  dnsNames:
  - ${var.internal_domain}
  EOF
  server_side_apply = true

  depends_on = [kubectl_manifest.remote_issuer]
}

# resource "kubectl_manifest" "remote_secret" {
#   yaml_body         = <<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-remote-issuer
#     namespace: ${var.namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-remote-issuer-key-pair"
#   EOF
#   server_side_apply = true

#   depends_on = [kubectl_manifest.remote_cert_issuer]
# }

# ###################signing#################
resource "kubectl_manifest" "signing_issuer" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
   name: "hpcc-signing-issuer"
   namespace: ${var.namespace}
  labels: 
    app.kubernetes.io/managed-by: "Helm"
  annotations:
    meta.helm.sh/release-name: "hpcc"
    meta.helm.sh/release-namespace: ${var.namespace}
  spec:
    selfSigned: {}
  EOF
  server_side_apply = true

}

resource "kubectl_manifest" "signing_cert_issuer" {

  yaml_body         = <<-EOF
 apiVersion: cert-manager.io/v1
 kind: Certificate
 metadata:
  name: "hpcc-signing-issuer"
  namespace: ${var.namespace}
 spec:
  secretName: "hpcc-signing-issuer-key-pair"
  subject:
   organizations:
   - HPCC Systems
   countries:
   - US
   organizationalUnits:
   - HPCC Example
   localities:
   - Alpharetta
   provinces:
   - Georgia
  isCA: true
  issuerRef:
    name: "hpcc-signing-issuer"
    kind: Issuer
  dnsNames:
  - ${var.internal_domain}
  EOF
  server_side_apply = true

  depends_on = [kubectl_manifest.signing_issuer]
}

# resource "kubectl_manifest" "signing_secret" {

#   yaml_body         = <<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-signing-issuer
#     namespace: ${var.namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-signing-issuer-key-pair"
#   EOF
#   server_side_apply = true

#   depends_on = [kubectl_manifest.signing_cert_issuer]
# }

# ##################public #####################

resource "kubernetes_manifest" "public_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
    {
      "name"      = "hpcc-public-issuer"
      "namespace" = var.namespace
    }
  ))
}

resource "kubernetes_manifest" "public_cert_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/certificate-issuer.yml",
    {
      "name"       = "hpcc-public-issuer"
      "secretName" = "hpcc-public-issuer-key-pair"
      "dnsNames"   = var.internal_domain
      "namespace"  = var.namespace
    }
  ))
  depends_on = [kubernetes_manifest.public_issuer]
}