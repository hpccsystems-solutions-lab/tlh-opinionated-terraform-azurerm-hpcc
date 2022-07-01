output "local_storage_values" {
  value = yamlencode(local.helm_chart_values.storage)
}