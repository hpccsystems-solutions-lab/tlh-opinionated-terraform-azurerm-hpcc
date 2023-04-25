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
  source          = "./modules/certmanager-zerossl"
  internal_domain = var.internal_domain
  namespace       = var.namespace.name

  depends_on = [kubernetes_namespace.default]
}

module "external_secrets" {
  source = "./modules/external_secrets"

  depends_on = [kubernetes_namespace.default]

  count = var.external_secrets.enabled ? 1 : 0

  namespace       = var.external_secrets.namespace
  vault_secret_id = var.external_secrets.vault_secret_id

  # secret_id = kubernetes_secret.secret_id.data
  # secrets   = kubernetes_secret.secrets.data
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
    kubernetes_secret.git_approle_secret_id,
    kubernetes_secret.ecl_approle_secret_id,
    kubernetes_secret.ecluser_approle_secret_id,
    kubernetes_secret.esp_approle_secret_id,
    module.node_tuning,
    module.certmanager,
    module.external_secrets,
    # kubectl_manifest.local_secret,
    # kubectl_manifest.remote_secret,
    # kubectl_manifest.signing_secret,
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