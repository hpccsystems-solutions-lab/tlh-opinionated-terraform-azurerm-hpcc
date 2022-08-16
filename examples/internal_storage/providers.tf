variable "default_connection_info" {
  description = "This variable is defined in the Terraform Enterprise workspace"
}
/*
variable "aad_group_id" {
  description = "Group id of the Vault Service Principal."
  default = "0c0851f0-5822-4c15-8a2f-08f0c3f1a15e"
  # This variable is populate by the Terraform Enterprise workspace"
}*/

terraform {
  required_version = "~>1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.57"
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




# provider "azurerm" {
#   storage_use_azuread        = true
#   skip_provider_registration = true
#   features {}
# }

# provider "kubernetes" {
#   host                   = module.aks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "kubelogin"
#     args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
#     env = {
#       AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
#       AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
#     }
#   }
# }

# # provider "kubectl" {
# #   host                   = module.aks.cluster_endpoint
# #   cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
# #   load_config_file       = false
# #   apply_retry_count      = 6

# #   exec {
# #     api_version = "client.authentication.k8s.io/v1beta1"
# #     command     = "kubelogin"
# #     args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
# #     env = {
# #       AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
# #       AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
# #     }
# #   }
# # }

# provider "helm" {
#   kubernetes {
#     host                   = module.aks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "kubelogin"
#       args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
#       env = {
#         AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
#         AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
#       }
#     }
#   }

#   experiments {
#     manifest = true
#   }
# }

# # provider "shell" {
# #   sensitive_environment = {
# #     AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
# #     AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
# #   }
# # }
