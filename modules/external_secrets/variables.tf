variable "namespace" {
  type = {
    name   = string
    labels = map(string)
  }
}

variable "vault_secret_id" {
  type = string
}