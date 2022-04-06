locals {
  storage_account_name_prefix = var.storage_account_name_prefix == null ? "hpcc${random_string.random.0.result}" : var.storage_account_name_prefix

  storage_plane_ids = toset([for v in range(1, var.data_plane_count + 1) : tostring(v)])
}