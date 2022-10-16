###local_issuer####
######
# resource "kubernetes_secret" "hpcc-local-secret" {
#   metadata {
#     name      = "hpcc-local-issuer-key-pair"
#     namespace = "hpcc"
#   }

#   data = {
#     "tls.crt" = file("${path.module}/local/tls.crt")
#     "tls.key" = file("${path.module}/local/tls.key")
#     "ca.crt"  = file("${path.module}/local/ca.crt")
#   }

#   type = "kubernetes.io/tls"
# }
resource "kubernetes_manifest" "local_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
    {
      "name" = "hpcc-local-issuer"
    }
  ))

  depends_on = [kubernetes_secret.hpcc-local-secret]
}

resource "kubernetes_manifest" "local_cert_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/certificate-issuer.yml",
    {
      "name"       = "hpcc-local-issuer"
      "secretName" = "hpcc-local-issuer-key-pair"
      "dnsNames"   = var.internal_domain
    }
  ))

  #depends_on = [kubernetes_manifest.local_issuer]
}

###############remote########################
# resource "kubernetes_secret" "hpcc-remote-secret" {
#   metadata {
#     name      = "hpcc-remote-issuer-key-pair"
#     namespace = "hpcc"
#   }

#   data = {
#     "tls.crt" = file("${path.module}/remote/tls.crt")
#     "tls.key" = file("${path.module}/remote/tls.key")
#     "ca.crt"  = file("${path.module}/remote/ca.crt")
#   }

#   type = "kubernetes.io/tls"
# }
resource "kubernetes_manifest" "remote_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
    {
      "name" = "hpcc-remote-issuer"
    }
  ))
  #depends_on = [kubernetes_secret.hpcc-remote-secret]
}

resource "kubernetes_manifest" "remote_cert_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/certificate-issuer.yml",
    {
      "name"       = "hpcc-remote-issuer"
      "secretName" = "hpcc-remote-issuer-key-pair"
      "dnsNames"   = var.internal_domain
    }
  ))
  depends_on = [kubernetes_manifest.remote_issuer]
}

###################signing#################
# resource "kubernetes_secret" "hpcc-signing-secret" {
#   metadata {
#     name      = "hpcc-signing-issuer-key-pair"
#     namespace = "hpcc"
#   }

#   data = {
#     "tls.crt" = file("${path.module}/signing/tls.crt")
#     "tls.key" = file("${path.module}/signing/tls.key")
#     "ca.crt"  = file("${path.module}/signing/ca.crt")
#   }

#   type = "kubernetes.io/tls"
# }
resource "kubernetes_manifest" "signing_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
    {
      "name" = "hpcc-signing-issuer"
    }
  ))
  depends_on = [kubernetes_secret.hpcc-signing-secret]
}

resource "kubernetes_manifest" "signing_cert_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/certificate-issuer.yml",
    {
      "name"       = "hpcc-signing-issuer"
      "secretName" = "hpcc-signing-issuer-key-pair"
      "dnsNames"   = var.internal_domain
    }
  ))

  #depends_on = [kubernetes_manifest.signing_issuer]
}

##################public #####################

resource "kubernetes_manifest" "public_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
    {
      "name" = "hpcc-public-issuer"
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
    }
  ))
  depends_on = [kubernetes_manifest.public_issuer]
}