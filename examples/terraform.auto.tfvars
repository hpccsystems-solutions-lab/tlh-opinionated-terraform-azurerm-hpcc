hpcc_data_plane_count = 2

# Naming

environment = "<lifecycle>" # Lifecycle environment - dev/nonprod/prod
productname = "<productname>"

jfrog_registry = {
  image_root = "useast.jfrog.lexisnexisrisk.com/glb-docker-virtual",
  image_name = "platform-core-ln",
  version    = "8.10.24"
}



# Network
cidr_block         = "10.0.0.0/24"
cidr_block_app     = "10.0.0.1/25"
cidr_block_storage = "10.0.0.2/26"
cidr_block_acr     = "10.0.0.4/26"

rbac_bindings = {
  cluster_admin_users = {
    "<email_id>" = "<object_id>"
  }
  cluster_view_users  = {}
  cluster_view_groups = []
}
default_connection_info = null
api_server_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}
storage_account_authorized_ip_ranges = {
  "alpharetta" = "66.241.32.0/19"
  "boca"       = "209.243.48.0/20"
  "tfe"        = "52.177.80.30"
}

