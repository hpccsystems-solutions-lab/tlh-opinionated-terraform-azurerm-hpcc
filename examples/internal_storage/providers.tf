variable "default_connection_info" {
  description = "This variable is defined in the Terraform Enterprise workspace"
}

terraform {
  required_version = "~>1.0"
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
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
      version = "~> 2.21"
    }
  }
}
provider "vault" {
  alias   = "azure_credentials"
  address = var.default_connection_info.vault_address
  token   = var.default_connection_info.vault_token
}
module "azure_credentials" {
  providers                 = { vault = vault.azure_credentials }
  source                    = "github.com/openrba/terraform-enterprise-azure-credentials.git?ref=v0.2.0"
  connection_info           = var.default_connection_info
  num_seconds_between_tests = 10
}
provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env.AZURE_TENANT_ID]
    env         = {
      AAD_SERVICE_PRINCIPAL_CLIENT_ID = module.azure_credentials.client_id
      AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = module.azure_credentials.client_secret
    }
  }
}
provider "kubectl" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
  load_config_file       = false
  apply_retry_count      = 6
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env.AZURE_TENANT_ID]
    env         = {
      AAD_SERVICE_PRINCIPAL_CLIENT_ID = module.azure_credentials.client_id
      AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = module.azure_credentials.client_secret
    }
  }
}
provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env.AZURE_TENANT_ID]
      env         = {
        AAD_SERVICE_PRINCIPAL_CLIENT_ID = module.azure_credentials.client_id
        AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = module.azure_credentials.client_secret
      }
    }
  }
  experiments {
    manifest = true
  }
}
provider "shell" {
  environment = {
    AZURE_SUBSCRIPTION_ID = module.azure_credentials.subscription_id
  }
  sensitive_environment = {
    AZURE_TENANT_ID = module.azure_credentials.tenant_id
    AZURE_CLIENT_ID = module.azure_credentials.client_id
    AZURE_CLIENT_SECRET = module.azure_credentials.client_secret
  }
}