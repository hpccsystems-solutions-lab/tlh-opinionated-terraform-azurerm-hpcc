variable "namespace" {
  description = "Namespace which is being scanned by Cron Job"
  type = string
}

variable "cron_job_settings" {
  description = "Variable to Set Cron Job Values"
  type = object({
    schedule = string
    starting_deadline_seconds = string
    successful_jobs_history_limit = string
    backoff_limit = string
    ttl_seconds_after_finished = string
    container_name = string
    container_image = string
    container_startup_command = list(string)
  })
}