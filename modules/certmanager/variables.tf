variable "internal_domain" {
  description = "DNS name."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources."
  type        = string
}

variable "cluster_name" {
  description = "The name of aks cluster."
  type        = string
}