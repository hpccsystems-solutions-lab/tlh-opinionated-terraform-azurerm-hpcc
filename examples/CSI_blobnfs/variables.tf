variable "config" {
  description = "cluster config"
  type        = any
  default     = {}
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users  = map(string)
      cluster_view_users   = map(string)
      standard_view_users  = map(string)
      standard_view_groups = map(string)
    }
  )
  default = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

variable "smtp_host" {
  description = "SMTP host and optionally appended port to send alerts to"
  type        = string
}

variable "smtp_from" {
  description = "Email address alerts are sent from"
  type        = string
}

variable "alerts_mailto" {
  description = "Email address alerts are sent to"
  type        = string
}

variable "namespace" {
  description = "Namespace for HPCC System"
  type        = string
}

variable "hpcc_helm_version" {
  description = "Version of the HPCC Helm Chart to use"
  type        = string
}

variable "hpcc_storage" {
  description = "Storage config for hpcc"
  type        = map(string)
}