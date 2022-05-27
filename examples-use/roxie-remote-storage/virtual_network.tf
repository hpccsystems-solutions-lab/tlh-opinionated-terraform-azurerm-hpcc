##
module "virtual_network_eastus" {
  source  = "tfe.lnrisk.io/Infrastructure/virtual-network/azurerm"
  version = "5.0.1"

  naming_rules        = module.naming_eastus.yaml
  resource_group_name = module.resource_group_eastus.name
  location            = module.resource_group_eastus.location
  names               = module.metadata_eastus.names
  tags                = module.metadata_eastus.tags

  address_space = [var.cidr_block_aks_eastus]

  aks_subnets = {
    roxie = {
      private = {
        cidrs                                          = [var.cidr_block_aks_app_eastus]
        service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
        enforce_private_link_endpoint_network_policies = true
        enforce_private_link_service_network_policies  = true
      }
      public = {
        cidrs                                          = [var.cidr_block_aks_storage_eastus]
        service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
        enforce_private_link_endpoint_network_policies = true
        enforce_private_link_service_network_policies  = true
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          internal-1 = {
            address_prefix         = "10.0.0.0/8"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = var.firewall_ip_eastus
          }
          internal-2 = {
            address_prefix         = "172.16.0.0/12"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = var.firewall_ip_eastus
          }
          internal-3 = {
            address_prefix         = "192.168.0.0/16"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = var.firewall_ip_eastus
          }
          local-vnet = {
            address_prefix = var.cidr_block_aks_eastus
            next_hop_type  = "vnetlocal"
          }
        }
      }
    }
  }

  peers = {
    expressroute = {
      id                           = var.expressroute_id_eastus
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = true
    }
    prod = {
      id                           = var.boolroxie_prod_vnet_id
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = false
    }
  }
}
