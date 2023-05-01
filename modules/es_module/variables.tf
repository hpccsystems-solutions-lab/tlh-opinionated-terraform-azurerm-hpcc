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
    secret_store_name      = string
    secret_store_namespace = string
    vault_url              = string
    vault_namespace        = string
    kv_path                = string
    approle_role_id        = string
    approle_secret_id_name = string
  }))
}

# variable "ext_secret" {
#   decrdescription = "A map of ExternalSecret names and their Vault Configuration""  
# }