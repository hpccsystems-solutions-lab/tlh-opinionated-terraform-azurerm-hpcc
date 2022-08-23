###local_issuer####
######

resource "kubernetes_manifest" "local_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
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
resource "null_resource" "local_issuer" {
  provisioner "local-exec" {
    command = <<EOF
  echo "-------- install kubectl on tfe runner ---------"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client
  echo "-------- install local ca ------------------"
  kubectl apply -f ${path.module}/local/ca-issuer.yml 
  echo "------------------------------------------------" 
  EOF
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks.kube_admin_config_raw
    }
  }
  depends_on = [kubernetes_manifest.local_cert_issuer]
}

###############remote########################

resource "kubernetes_manifest" "remote_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
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

resource "null_resource" "remote_issuer" {
  provisioner "local-exec" {
    command = <<EOF
  echo "-------- install local ca ------------------"
  kubectl apply -f ${path.module}/remote/ca-issuer.yml 
  echo "------------------------------------------------" 
  EOF
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks.kube_admin_config_raw
    }
  }
  depends_on = [null_resource.local_issuer, kubernetes_manifest.remote_cert_issuer]
}

###################signing#################

resource "kubernetes_manifest" "signing_issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml",
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

resource "null_resource" "signing_issuer" {
  provisioner "local-exec" {
    command = <<EOF
  echo "-------- install local ca ------------------"
  kubectl apply -f ${path.module}/signing/ca-issuer.yml 
  echo "------------------------------------------------" 
  EOF
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks.kube_admin_config_raw
    }
  }
  depends_on = [null_resource.local_issuer, kubernetes_manifest.signing_cert_issuer]
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