data "azurerm_kubernetes_cluster" "aks_kubeconfig" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subscription" "current" {}