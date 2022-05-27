variable "default_connection_info" {
  description = "This variable is defined in the Terraform Enterprise workspace"
}

provider "vault" {
  alias   = "azure_credentials"
  address = var.default_connection_info.vault_address
  token   = var.default_connection_info.vault_token
  version = "= 2.18.0"
}

module "default_azure_credentials" {
  providers = { vault = vault.azure_credentials }
  source    = "github.com/openrba/terraform-enterprise-azure-credentials.git?ref=v0.2.0"

  connection_info = var.default_connection_info
}

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
      version = "~> 2.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
  }
}

provider "azurerm" {
  #version = "=2.89.0"

  tenant_id       = module.default_azure_credentials.tenant_id
  subscription_id = module.default_azure_credentials.subscription_id
  client_id       = module.default_azure_credentials.client_id
  client_secret   = module.default_azure_credentials.client_secret
  storage_use_azuread = true

  features {}
}

provider "azuread" {
  #version = "=1.2.2"

  tenant_id     = module.default_azure_credentials.tenant_id
  client_id     = module.default_azure_credentials.client_id
  client_secret = module.default_azure_credentials.client_secret
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  load_config_file       = false
}

