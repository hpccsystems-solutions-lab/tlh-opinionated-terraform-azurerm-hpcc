variable "namespace" {
  type = object({
    name   = string
    labels = map(string)
  })
}

variable "vault_secret_id" {
  type = string
}

# variable "secret_stores" {
#   description = "A map of SecretStore names and their Vault Configuration"
#   type = map(object({
#     name = string
#     namespace = string
#     vault_url = string
#     vault_role_id = string
#     vault_secret_name = string
#     vault_namespace = string
#     vault_path = string
#   }))
# }

# variable "ext_secret" {
#   decrdescription = "A map of ExternalSecret names and their Vault Configuration""  
# }