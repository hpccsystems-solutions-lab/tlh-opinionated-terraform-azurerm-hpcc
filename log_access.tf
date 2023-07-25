# # Role Assignment for Accessing Enterprise Application.

# resource "azurerm_role_assignment" "log_access_subscription" {

#   scope                = coalesce(var.log_access_role_assignment.scope, data.azurerm_subscription.current.id)
#   role_definition_name = "Log Analytics Contributor"
#   principal_id         = var.log_access_role_assignment.object_id
# }