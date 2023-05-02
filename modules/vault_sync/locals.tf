locals {
  container_image = coalesce(var.cron_job_settings.container_image, format("%s%scr.azurecr.io/vault_image/vault_image:latest", var.productname, var.environment))
}