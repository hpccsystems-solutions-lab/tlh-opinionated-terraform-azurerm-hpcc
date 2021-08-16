output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.aks_cluster_name} --resource-group ${var.resource_group_name}"
}