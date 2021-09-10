data "azurerm_storage_account" "storage_account" {
    count = var.hpcc_storage_account_name != "" ? 1 : 0
    name =  var.hpcc_storage_account_name
    resource_group_name = var.resource_group_name
}