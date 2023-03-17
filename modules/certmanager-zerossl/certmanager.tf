###local_issuer####
######
resource "kubectl_manifest" "default_issuer" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
   name: "hpcc-default-issuer"
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
  ignore_fields     = ["metadata.annotations", "metadata.labels", "spec.selfSigned"]
}

resource "kubectl_manifest" "local_certificate" {

  yaml_body         = <<-EOF
 apiVersion: cert-manager.io/v1
 kind: Certificate
 metadata:
  name: "hpcc-local-certificate"
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
    name: "hpcc-default-issuer"
    kind: Issuer
  dnsNames:
  - ${var.internal_domain}
  EOF
  server_side_apply = true

  depends_on = [kubectl_manifest.default_issuer]
}

# Remote Certificate
resource "kubectl_manifest" "remote_certificate" {

  yaml_body         = <<-EOF
 apiVersion: cert-manager.io/v1
 kind: Certificate
 metadata:
  name: "hpcc-remote-certificate"
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
    name: "hpcc-default-issuer"
    kind: Issuer
  dnsNames:
  - ${var.internal_domain}
  EOF
  server_side_apply = true

  depends_on = [kubectl_manifest.default_issuer]
}


resource "kubectl_manifest" "signing_certificate" {

  yaml_body         = <<-EOF
 apiVersion: cert-manager.io/v1
 kind: Certificate
 metadata:
  name: "hpcc-signing-certificate"
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
    name: "hpcc-default-issuer"
    kind: Issuer
  dnsNames:
  - ${var.internal_domain}
  EOF
  server_side_apply = true

  depends_on = [kubectl_manifest.default_issuer]

}


resource "kubernetes_manifest" "public_cert_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/certificate.yml",
    {
      "name"       = "hpcc-public-certificate"
      "secretName" = "hpcc-public-issuer-key-pair"
      "issuerName" = "zerossl"
      "dnsNames"   = var.internal_domain
      "namespace"  = "cert-manager"
    }
  ))
}