terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.19"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "~> 1.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7.2"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.21"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {}
}

#provider "kubernetes" {
#  host                   = module.aks.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
#
#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    command     = "kubelogin"
#    args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
#    env = {
#      AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
#      AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
#    }
#  }
#}
#
#provider "kubectl" {
#  host                   = module.aks.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
#  load_config_file       = false
#  apply_retry_count      = 6
#
#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    command     = "kubelogin"
#    args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
#    env = {
#      AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
#      AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
#    }
#  }
#}
#
#provider "helm" {
#  kubernetes {
#    host                   = module.aks.cluster_endpoint
#    cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
#
#    exec {
#      api_version = "client.authentication.k8s.io/v1beta1"
#      command     = "kubelogin"
#      args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
#      env = {
#        AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
#        AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
#      }
#    }
#  }
#
#  experiments {
#    manifest = true
#  }
#}
#
#provider "shell" {
#  sensitive_environment = {
#    AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
#    AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
#  }
#}