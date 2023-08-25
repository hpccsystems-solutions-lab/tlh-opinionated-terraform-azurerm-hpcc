output "hpcc_status" {
  description = "The status of the HPCC deployment."
  value       = helm_release.hpcc.status
}
