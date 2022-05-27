#
module "naming_eastus" {
  source  = "tfe.lnrisk.io/Infrastructure/naming/azurerm"
  version = "1.0.81"
}

module "metadata_eastus" {
  source  = "tfe.lnrisk.io/Infrastructure/metadata/azurerm"
  version = "1.5.2"

  naming_rules = module.naming_eastus.yaml

  market              = "us"
  project             = "hpccops"
  location            = "eastus"
  sre_team            = "SupercomputerOps@lexisnexisrisk.com"
  environment         = "dev"
  product_name        = "boolroxie"
  business_unit       = "iog"
  product_group       = "hpccops"
  subscription_id     = data.azurerm_subscription.current.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group_eastus" {
  source   = "tfe.lnrisk.io/Infrastructure/resource-group/azurerm"
  version  = "2.0.0"
  location = module.metadata_eastus.location
  names    = module.metadata_eastus.names
  tags     = module.metadata_eastus.tags
}

