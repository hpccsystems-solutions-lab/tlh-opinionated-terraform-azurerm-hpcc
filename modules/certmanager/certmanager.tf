###local_issuer####
######

resource "kubernetes_manifest" "local_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/local/issuer.yml",
    {
      "name" = "hpcc-local-issuer"
    }
  ))
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

  depends_on = [kubernetes_manifest.local_issuer]
}

###############remote########################

resource "kubernetes_manifest" "remote_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/remote/issuer.yml",
    {
      "name" = "hpcc-remote-issuer"
    }
  ))
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

resource "kubernetes_manifest" "signing_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/signing/issuer.yml",
    {
      "name" = "hpcc-signing-issuer"
    }
  ))
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

  depends_on = [kubernetes_manifest.signing_issuer]
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