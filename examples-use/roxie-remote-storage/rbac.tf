#########
# RBAC  #
#########


resource "azurerm_role_assignment" "hpcc_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "users_acr_pull" {
  for_each                         = var.azuread_clusterrole_map["cluster_admin_users"]
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = each.value
}

resource "azurerm_role_assignment" "users_acr_push" {
  for_each                         = var.azuread_clusterrole_map["cluster_admin_users"]
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPush"
  principal_id                     = each.value
}

