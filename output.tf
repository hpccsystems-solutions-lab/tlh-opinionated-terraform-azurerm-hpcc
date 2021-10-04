output "aks_login" {
  value = "az aks get-credentials --name ${module.aks.cluster_name} --resource-group ${var.resource_group_name}"
}