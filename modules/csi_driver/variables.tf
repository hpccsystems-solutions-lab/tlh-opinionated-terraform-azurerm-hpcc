variable "create_namespace" {
  description = "Create kubernetes namespace."
  type        = bool
  default     = true
}

variable "helm_chart_version" {
  description = "Helm chart version."
  type        = string
  default     = "v1.9.0"
}

variable "namespace" {
  description = "Namespace in which to install the csi driver."
  type = object({
    name   = string
    labels = map(string)
  })
  default = {
    name = "blob-csi-driver"
    labels = {
      name = "blob-csi-driver"
    }
  }
}