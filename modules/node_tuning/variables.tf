variable "containers" {
  description = "URIs for containers."
  type        = object({
    busybox = string
    debian  = string
  })
  default = {
    busybox = "docker.io/library/busybox:1.34"
    debian  = "docker.io/library/debian:bullseye-slim"
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