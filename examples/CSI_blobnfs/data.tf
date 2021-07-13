data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

data "azurerm_subscription" "current" {
}

data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = module.aks.aks_cluster_name
  resource_group_name = module.resource_group.name
}