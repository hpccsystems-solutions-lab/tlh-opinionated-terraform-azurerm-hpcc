
output "mariadb_instance_manifests" {
  value = data.helm_template.hpcc.manifests
}

output "mariadb_instance_notes" {
  value = data.helm_template.hpcc.notes
}