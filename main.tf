resource "kubernetes_namespace" "default" {
  metadata {
    name   = var.namespace.name
    labels = var.namespace.labels
  }
}

module "node_tuning" {
  source = "./modules/node_tuning"

  count = var.enable_node_tuning ? 1 : 0

  # containers              = var.node_tuning_containers
  containers = local.acr_default

  container_registry_auth = var.node_tuning_container_registry_auth

}

module "certmanager" {
  source              = "./modules/certmanager"
  internal_domain     = var.internal_domain
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  namespace           = var.namespace.name

  depends_on = [kubernetes_namespace.default]
}

resource "kubectl_manifest" "remote_secret" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: hpcc-remote-issuer
    namespace: ${var.namespace.name}
  spec:
    ca: 
     secretName: "hpcc-remote-issuer-key-pair"
  EOF
  server_side_apply = true

  depends_on = [module.certmanager]
}

resource "kubectl_manifest" "local_secret" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: hpcc-local-issuer
    namespace: ${var.namespace.name}
  spec:
    ca: 
     secretName: "hpcc-local-issuer-key-pair"
  EOF
  server_side_apply = true

  depends_on = [module.certmanager]
}

resource "kubectl_manifest" "signing_secret" {

  yaml_body         = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: hpcc-signing-issuer
    namespace: ${var.namespace.name}
  spec:
    ca: 
     secretName: "hpcc-signing-issuer-key-pair"
  EOF
  server_side_apply = true

  depends_on = [module.certmanager]
}

####################

resource "null_resource" "annotations_name" {
  provisioner "local-exec" {
    command = <<EOF
  echo "--------------Install KUBECTL on TFE-----------------"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client
  echo "------------Adding Annotation for local issuer ------------------"
  kubectl annotate issuer hpcc-local-issuer -n hpcc meta.helm.sh/release-name="hpcc"
  echo "Adding Annotation for signing issuer"
  kubectl annotate issuer hpcc-signing-issuer -n hpcc meta.helm.sh/release-name="hpcc"
  echo "Adding Annotation for remote issuer"
  kubectl annotate issuer hpcc-remote-issuer -n hpcc meta.helm.sh/release-name="hpcc"
  echo "Deleted ECL Services Service"
  echo "------------------------------------------------" 
  EOF
  interpreter = ["bash", "-C"]
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks_kubeconfig.kube_admin_config_raw
    }
  }
   depends_on = [module.certmanager,
     kubectl_manifest.local_secret,
     kubectl_manifest.signing_secret,
     kubectl_manifest.remote_secret]
}

resource "null_resource" "annotations_namespace" {
  provisioner "local-exec" {
    command = <<EOF
  echo "--------------Install KUBECTL on TFE-----------------"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client
  echo "------------Adding Annotation for local issuer ------------------"
  kubectl annotate issuer hpcc-local-issuer -n hpcc meta.helm.sh/release-namespace="hpcc"
  echo "Adding Annotation for signing issuer"
  kubectl annotate issuer hpcc-signing-issuer -n hpcc meta.helm.sh/release-namespace="hpcc"
  echo "Adding Annotation for remote issuer"
  kubectl annotate issuer hpcc-remote-issuer -n hpcc meta.helm.sh/release-namespace="hpcc"
  echo "Deleted ECL Services Service"
  echo "------------------------------------------------" 
  EOF
  interpreter = ["bash", "-C"]
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks_kubeconfig.kube_admin_config_raw
    }
  }
   depends_on = [module.certmanager,
     kubectl_manifest.local_secret,
     kubectl_manifest.signing_secret,
     kubectl_manifest.remote_secret]
}

resource "null_resource" "labels" {
  provisioner "local-exec" {
    command = <<EOF
  echo "--------------Install KUBECTL on TFE-----------------"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client
  echo "------------Adding label for local issuer ------------------"
  kubectl label issuer hpcc-local-issuer -n hpcc app.kubernetes.io/managed-by="Helm" 
  echo "Adding label for signing issuer"
  kubectl label issuer hpcc-signing-issuer -n hpcc app.kubernetes.io/managed-by="Helm"
  echo "Adding label for remote issuer"
  kubectl label issuer hpcc-remote-issuer -n hpcc app.kubernetes.io/managed-by="Helm"
  echo "Deleted ECL Services Service"
  echo "------------------------------------------------" 
  EOF
  interpreter = ["bash", "-C"]
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks_kubeconfig.kube_admin_config_raw
    }
  }
   depends_on = [module.certmanager,
     kubectl_manifest.local_secret,
     kubectl_manifest.signing_secret,
     kubectl_manifest.remote_secret]
}

## Adding Script to delete K8s Services due to release v0.9.2 of the module. 

resource "null_resource" "service_delete_script" {
  provisioner "local-exec" {
    command = <<EOF
  echo "--------------Install KUBECTL on TFE-----------------"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client
  echo "------------Start Deleting Services ------------------"
  kubectl delete svc sasha-coalescer -n hpcc
  echo "Deleted Sasha Coalescer Service"
  kubectl delete svc eclservices -n hpcc
  echo "Deleted ECL Services Service"
  echo "------------------------------------------------" 
  EOF
    environment = {
      KUBECONFIG = data.azurerm_kubernetes_cluster.aks_kubeconfig.kube_admin_config_raw
    }
  }
}

resource "helm_release" "hpcc" {
  depends_on = [
    kubernetes_namespace.default,
    kubernetes_persistent_volume_claim.azurefiles,
    kubernetes_persistent_volume_claim.blob_nfs,
    kubernetes_persistent_volume_claim.hpc_cache,
    kubernetes_persistent_volume_claim.spill,
    kubernetes_secret.hpcc_container_registry_auth,
    kubernetes_secret.dali_hpcc_admin,
    kubernetes_secret.dali_ldap_admin,
    kubernetes_secret.esp_ldap_admin,
    module.node_tuning,
    module.certmanager,
    null_resource.service_delete_script
  ]

  timeout = var.helm_chart_timeout

  name       = "hpcc"
  namespace  = var.namespace.name
  chart      = "hpcc"
  repository = "https://hpcc-systems.github.io/helm-chart"
  version    = var.helm_chart_version
  values = [
    yamlencode(local.helm_chart_values),
    var.helm_chart_overrides
  ]
}