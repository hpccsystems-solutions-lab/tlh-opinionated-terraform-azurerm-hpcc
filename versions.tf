terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.78.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=2.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.1.1"
    }
  }
  required_version = ">=0.14.8"
}