variable "helm_namespace" {
  type = object({
    name   = string
    labels = map(string)
  })
}

variable "application_namespace" {
  type = string
}

variable "vault_secret_id" {
  type = object({
    name         = string
    secret_value = string
  })
}

variable "secret_stores" {
  description = "A map of SecretStore names and their Vault Configuration"
  type = map(object({
    secret_store_name = string
    vault_url         = string
    vault_namespace   = string
    vault_kv_path     = string
    approle_role_id   = string
  }))
}

variable "secrets" {
  description = "A map of External Secrets object, includes Remote Vault KV details"
  type = map(object({
    target_secret_name = string
    remote_secret_name = string
    secret_store_name  = string
  }))
}