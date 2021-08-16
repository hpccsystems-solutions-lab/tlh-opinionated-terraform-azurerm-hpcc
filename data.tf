data "azurerm_kubernetes_cluster" "aks_cluster" {
  depends_on = [
    module.aks
  ]
  name                = module.aks.aks_cluster_name
  resource_group_name = var.resource_group_name
}