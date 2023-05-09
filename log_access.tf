# Role Assignment for Accessing Enterprise Application.


resource "azurerm_role_assignment" "log_access_subscription" {

  scope                = coalesce(var.log_access_role_assignment.scope, data.azurerm_subscription.current.subscription_id)
  role_definition_name = "Log Analytics Contributor"
  principal_id         = coalesce(var.log_access_role_assignment.object_id, local.log_access_app_object_id)
}