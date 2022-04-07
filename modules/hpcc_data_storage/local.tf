locals {
  storage_plane_ids = toset([for v in range(1, var.data_plane_count + 1) : tostring(v)])
}