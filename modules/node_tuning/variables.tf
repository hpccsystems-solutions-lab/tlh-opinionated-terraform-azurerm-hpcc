variable "containers" {
  description = "URIs for containers."
  type        = object({
    busybox = string
    debian  = string
  })
  default = {
    busybox = local.acr_defaults.busybox
    debian  = local.acr_defaults.debian
  }
}

variable "container_registry_auth" {
  description = "Registry authentication for containers."
  type        = object({
    password   = string
    username   = string
  })
  default = null
  sensitive = true
}

variable "create_namespace" {
  description = "Create kubernetes namespace."
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace in which to install node tuning daemonset"
  type = object({
    name   = string
    labels = map(string)
  })
  default = {
    name = "hpcc-node-tuning"
    labels = {
      name = "hpcc-node-tuning"
    }
  }
}

variable "environment" {
  description = "Environment HPCC is being deployed to."
  type = string
  default = "dev"
}

variable "productname" {
  description = "Environment HPCC is being deployed to."
  type = string
}
