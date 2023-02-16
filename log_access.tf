# Kubernetes Secret for Log Access from log_access_config variable 

resource "kubernetes_secret" "azure_log_analytics_workspace" {
  depends_on = [
    kubernetes_namespace.default
  ]

  count = var.log_access_config != null ? 1 : 0

  metadata {
    name      = "azure-logaccess"
    namespace = var.namespace.name
    labels = {
      name = "azure-logaccess"
    }
  }

  data = {
    "aad-client-id"     = var.log_access_config.AAD_CLIENT_ID
    "aad-tenant-id"     = var.log_access_config.AAD_TENANT_ID
    "aad-client-secret" = var.log_access_config.AAD_CLIENT_SECRET
    "ala-workspace-id"  = var.log_access_config.LAW_WORKSPACE_ID
  }

  type = "kubernetes.io/generic"
}

resource "azurerm_role_assignment" "azure_log_analytics_workspace" {
  scope                = var.log_access_config.LAW_SCOPE
  role_definition_name = "Log Analytics Contributor"
  principal_id         = var.log_access_config.LAW_ID
}