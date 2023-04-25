variable "namespace" {
  type = object({
    name   = string
    labels = map(string)
  })
}

variable "vault_secret_id" {
  type = string
}