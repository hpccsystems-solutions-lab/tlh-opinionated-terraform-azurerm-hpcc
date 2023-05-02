variable "application_namespace" {
  description = "Namespace which is being scanned by Cron Job"
  type = string
}

variable "cron_job_settings" {
  description = "Variable to Set Cron Job Values"
  type = object({
    schedule = string
    starting_deadline_seconds = number
    successful_jobs_history_limit = number
    backoff_limit = number
    ttl_seconds_after_finished = number
    container_name = string
    container_image = string
    container_startup_command = list(string)
    container_environment_settings = map(string)
    failed_jobs_history_limit = number
  })
}

variable "environment" {
  description = "Environment name where the resources are being deployed"
  type = string
}

variable "productname" {
  description = "Product name which is being deployed"
  type = string
}