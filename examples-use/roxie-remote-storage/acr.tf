/*
module "acr" {
  source  = "git@github.com:LexisNexis-RBA/terraform-azurerm-container-registry.git"

  location                 = module.metadata_eastus.location
  resource_group_name      = module.resource_group_eastus.name
  names                    = module.metadata_eastus.names
  tags                     = module.metadata_eastus.tags

  sku                      = "Premium"

  georeplications = [
    {
      location = "CentralUS"
      tags     = { "purpose" =  "Primary DR Region" }
    }
  ]
  admin_enabled            = true
  acr_contributors = { aks = module.aks.kubelet_identity.object_id }
  acr_readers = { "aks" = module.aks.principal_id }
  acr_admins = {
    "wagnerrh@risk.regn.net" = "272aa8b3-a811-4be6-9d8f-60f317b2af97",
    "orocheex@risk.regn.net" = "464d3990-d153-4022-859f-038593f0b3ed",
    "fernanux@risk.regn.net" = "f3757f75-96dc-4c92-8fde-f029b42100b7"
  }

  service_endpoints = {
    "iaas-outbound" = module.virtual_network_eastus.aks["roxie"].subnets["private"].id
  }
}
*/

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
