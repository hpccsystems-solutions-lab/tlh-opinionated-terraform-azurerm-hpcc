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