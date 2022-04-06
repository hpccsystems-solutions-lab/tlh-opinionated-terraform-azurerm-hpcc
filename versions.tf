terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.85.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=2.3.0"
    }
  }
  required_version = ">=1.0.0"
}