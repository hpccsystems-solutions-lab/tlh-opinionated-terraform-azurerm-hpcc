resource "random_string" "random" {
  count = var.name == null ? 1 : 0

  length  = 12
  upper   = false
  number  = false
  special = false
}

resource "azurerm_hpc_cache" "default" {
  name                = local.hpc_cache_name
  resource_group_name = var.resource_group_name
  location            = var.location
  cache_size_in_gb    = local.hpc_cache_info[var.size].cache_size_in_gb
  subnet_id           = var.subnet_id
  sku_name            = local.hpc_cache_info[var.size].sku

  timeouts {
    create = "30m"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "default" {
  for_each = local.hpc_cache_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = var.resource_provider_object_id
}

resource "azurerm_hpc_cache_blob_nfs_target" "default" {
  depends_on = [
    azurerm_role_assignment.default,
    azurerm_hpc_cache.default,
  ]

  for_each = local.storage_planes

  name                 = "${each.value.storage_account_name}-${each.value.container_name}"
  resource_group_name  = var.resource_group_name
  cache_name           = azurerm_hpc_cache.default.name
  storage_container_id = each.value.container_id
  namespace_path       = "/${each.value.dataset}-hpcc-data-${each.value.id}"
  usage_model          = each.value.usage_model
}

resource "azurerm_dns_a_record" "default" {
  depends_on = [
    azurerm_hpc_cache_blob_nfs_target.default
  ]

  name                = azurerm_hpc_cache.default.name
  zone_name           = var.dns.zone_name
  resource_group_name = var.dns.zone_resource_group_name
  ttl                 = 300
  records             = azurerm_hpc_cache.default.mount_addresses

  tags = var.tags
}