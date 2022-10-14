# Storage Class for Premium ZRS Storage Account

resource "kubernetes_storage_class" "premium_zrs_file_share_storage_class" {
  metadata {
    name = "hpcc-premium-zrs-file-share-sc"
  labels = {
      storage-tier = "azurefiles"
    }
  }
  storage_provisioner = "file.csi.azure.com"
  reclaim_policy      = "Retain"
  parameters = {
    skuName        = "Premium_ZRS"
    location       = var.location
    resourceGroup  = var.resource_group_name
    storageAccount = azurerm_storage_account.azurefiles_admin_services.0.name
    storeAccountKey = azurerm_storage_account.azurefiles_admin_services.0.primary_access_key
  }
  mount_options = local.azure_files_pv_protocol == "nfs" ? ["nconnect=8"] : ["file_mode=0644", "dir_mode=0755", "mfsymlinks", "uid=10000", "gid=10001", "actimeo=30", "cache=strict"]
}
