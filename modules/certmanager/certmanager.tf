###local_issuer####
######
# resource "kubernetes_secret" "hpcc-local-secret" {
#   metadata {
#     name      = "hpcc-local-issuer-key-pair"
#     namespace = var.namespace
#   }

#   data = {
#     "tls.crt" = file("${path.module}/local/tls.crt")
#     "tls.key" = file("${path.module}/local/tls.key")
#   }

#   type = "kubernetes.io/tls"
# }
# resource "kubernetes_manifest" "local_issuer" {
#   #provider = kubectl.stable
#   manifest = yamldecode(templatefile(
#     "${path.module}/local/issuer.yml",
#     {
#       "name"      = "hpcc-local-issuer"
#       "namespace" = var.namespace
#     }
#   ))

#   # depends_on = [kubernetes_secret.hpcc-local-secret]
# }

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

  # depends_on = [module.certmanager]
}


# resource "kubernetes_manifest" "local_cert_issuer" {
#   # provider = kubectl.stable
#   manifest = yamldecode(templatefile(
#     "${path.module}/certificate-issuer.yml",
#     {
#       "name"       = "hpcc-local-issuer"
#       "secretName" = "hpcc-local-issuer-key-pair"
#       "dnsNames"   = var.internal_domain
#       "namespace"  = var.namespace
#     }
#   ))

#   depends_on = [kubernetes_manifest.local_issuer]
# }

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

# resource "kubernetes_manifest" "secretstores" {

#   # provider = kubectl

#   manifest = yamldecode(<<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-local-issuer
#     namespace: ${var.namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-local-issuer-key-pair"
#   EOF
#   )

#   depends_on = [kubernetes_manifest.local_cert_issuer]
# }

# ###############remote########################
# resource "kubernetes_secret" "hpcc-remote-secret" {
#   metadata {
#     name      = "hpcc-remote-issuer-key-pair"
#     namespace = var.namespace
#   }

#   data = {
#     "tls.crt" = file("${path.module}/remote/tls.crt")
#     "tls.key" = file("${path.module}/remote/tls.key")
#   }

#   type = "kubernetes.io/tls"
# }
# resource "kubernetes_manifest" "remote_issuer" {
#   #provider = kubectl.stable
#   manifest = yamldecode(templatefile(
#     "${path.module}/remote/issuer.yml",
#     {
#       "name"      = "hpcc-remote-issuer"
#       "namespace" = var.namespace
#     }
#   ))
#   #depends_on = [kubernetes_secret.hpcc-remote-secret]
# }

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

  # depends_on = [module.certmanager]
}

# resource "kubernetes_manifest" "remote_cert_issuer" {
#   # provider = kubectl.stable
#   manifest = yamldecode(templatefile(
#     "${path.module}/certificate-issuer.yml",
#     {
#       "name"       = "hpcc-remote-issuer"
#       "secretName" = "hpcc-remote-issuer-key-pair"
#       "dnsNames"   = var.internal_domain
#       "namespace"  = var.namespace
#     }
#   ))
#   depends_on = [kubernetes_manifest.remote_issuer]
# }

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

# resource "kubernetes_manifest" "remote_secret" {

#   # provider = kubectl

#   manifest = yamldecode(<<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-remote-issuer
#     namespace: ${var.namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-remote-issuer-key-pair"
#   EOF
#   )

#   depends_on = [kubernetes_manifest.remote_cert_issuer]
# }

# ###################signing#################
# resource "kubernetes_secret" "hpcc-signing-secret" {
#   metadata {
#     name      = "hpcc-signing-issuer-key-pair"
#     namespace = var.namespace
#   }

#   data = {
#     "tls.crt" = file("${path.module}/signing/tls.crt")
#     "tls.key" = file("${path.module}/signing/tls.key")
#   }

#   type = "kubernetes.io/tls"
# }
# resource "kubernetes_manifest" "signing_issuer" {
#   #provider = kubectl.stable
#   manifest = yamldecode(templatefile(
#     "${path.module}/signing/issuer.yml",
#     {
#       "name"      = "hpcc-signing-issuer"
#       "namespace" = var.namespace
#     }
#   ))
#   #depends_on = [kubernetes_secret.hpcc-signing-secret]
# }

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

  # depends_on = [module.certmanager]
}

# resource "kubernetes_manifest" "signing_cert_issuer" {
#   # provider = kubectl.stable
#   manifest = yamldecode(templatefile(
#     "${path.module}/certificate-issuer.yml",
#     {
#       "name"       = "hpcc-signing-issuer"
#       "secretName" = "hpcc-signing-issuer-key-pair"
#       "dnsNames"   = var.internal_domain
#       "namespace"  = var.namespace
#     }
#   ))

#   depends_on = [kubernetes_manifest.signing_issuer]
# }

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

# resource "kubernetes_manifest" "signing_secret" {

#   # provider = kubectl

#   manifest = yamldecode(<<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-signing-issuer
#     namespace: ${var.namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-signing-issuer-key-pair"
#   EOF
#   )

#   depends_on = [kubernetes_manifest.signing_cert_issuer]
#}

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

# resource "kubectl_manifest" "remote_secret" {

#  # provider = kubectl

#   yaml_body         = <<-EOF
#   apiVersion: cert-manager.io/v1
#   kind: Issuer
#   metadata:
#     name: hpcc-remote-issuer
#     namespace: ${namespace}
#   spec:
#     ca: 
#      secretName: "hpcc-remote-issuer-key-pair"
#   EOF
#   server_side_apply = true

#   depends_on = [kubernetes_manifest.remote_cert_issuer]
# }