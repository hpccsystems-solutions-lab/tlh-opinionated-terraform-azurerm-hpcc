# data "azurerm_subscription" "current" {}

# data "azuread_group" "subscription_owner" {
#   display_name = "ris-azr-group-${data.azurerm_subscription.current.display_name}-owner"
# }

# data "http" "my_ip" {
#   url = "https://ifconfig.me"
# }

# data "azuread_service_principal" "hpc_cache_resource_provider" {
#   display_name = "HPC Cache Resource Provider"
# }

# # Random string for resource group
# resource "random_string" "random" {
#   length  = 12
#   upper   = false
#   number  = false
#   special = false
# }
