#######
# ACR #
#######

resource "azurerm_container_registry" "acr" {
  name                = "eastboolacr"
  resource_group_name = module.resource_group_eastus.name
  location            = module.resource_group_eastus.location
  sku                 = "Premium"
  admin_enabled       = true
  tags                = module.metadata_eastus.tags

  network_rule_set = [
    {
      default_action = "Deny"
      ip_rule = [
        {
          action   = "Allow"
          ip_range = "209.243.55.0/24"
        },
        {
          action   = "Allow"
          ip_range = "66.241.32.0/24"
        }
      ]
      virtual_network = [
        {
          action    = "Allow"
          subnet_id = module.virtual_network_eastus.aks["roxie"].subnets["private"].id

        }
      ]
    }
  ]
}
