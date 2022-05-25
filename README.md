# terraform-azurerm-hpcc

## Overview

This module is designed to provide a simple and opinionated way to build standard HPCC Systems Platforms and utilizes the [terraform-azurerm-aks](https://github.com/LexisNexis-RBA/terraform-azurerm-aks) module. This module takes a set of configuration options and creates a fully functional HPCC Systems deployment.

---

## Support Policy

Support and use of this module.

---

## Requirements

1.  Since this module utilizes the [terraform-azurerm-aks](https://github.com/LexisNexis-RBA/terraform-azurerm-aks) module, be sure to consult its requirements [
[documentation](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/docs).

    In particular, carefully review networking and DNS requirements.

2.  This module requires an authenticated container registry to deliver the hpcc systems images.
    *  If using Jfrog directly (NOT recommended, but may be acceptable for development use), you will need to request viewer access to glb project in [Jfrog](https://useast.jfrog.lexisnexisrisk.com/).
---

## Usage

This module is designed to provide a standard, opinonated, but configurable, deployment of the HPCC Systems platform on AKS.

See [examples](/examples) for general usage.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=2.85.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >=2.1.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >=2.5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=2.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=2.85.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >=2.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >=2.5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >=2.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_csi_driver"></a> [csi\_driver](#module\_csi\_driver) | ./modules/csi_driver | n/a |
| <a name="module_data_cache"></a> [data\_cache](#module\_data\_cache) | ./modules/hpcc_data_cache | n/a |
| <a name="module_data_storage"></a> [data\_storage](#module\_data\_storage) | ./modules/hpcc_data_storage | n/a |
| <a name="module_node_tuning"></a> [node\_tuning](#module\_node\_tuning) | ./modules/node_tuning | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.protect_admin_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_storage_account.azurefiles_admin_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.blob_nfs_admin_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.blob_nfs_admin_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_share.azurefiles_admin_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [helm_release.hpcc](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.eclqueries](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.eclwatch](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.esdl_sandbox](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.roxie](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.sql2ecl](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_persistent_volume.azurefiles](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume) | resource |
| [kubernetes_persistent_volume.blob_nfs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume) | resource |
| [kubernetes_persistent_volume.hpc_cache](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume) | resource |
| [kubernetes_persistent_volume.spill](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume) | resource |
| [kubernetes_persistent_volume_claim.azurefiles](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.blob_nfs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.hpc_cache](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.spill](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.azurefiles_admin_services](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.dali_hpcc_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.dali_ldap_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.esp_ldap_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.hpcc_container_registry_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_uuid.volume_handle](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_services_node_selector"></a> [admin\_services\_node\_selector](#input\_admin\_services\_node\_selector) | Node selector for admin services pods. | `map(map(string))` | `{}` | no |
| <a name="input_admin_services_storage"></a> [admin\_services\_storage](#input\_admin\_services\_storage) | PV sizes for admin service planes in gigabytes (storage billed only as consumed). | <pre>object({<br>    dali = object({<br>      size = number<br>      type = string<br>    })<br>    debug = object({<br>      size = number<br>      type = string<br>    })<br>    dll = object({<br>      size = number<br>      type = string<br>    })<br>    lz = object({<br>      size = number<br>      type = string<br>    })<br>    sasha = object({<br>      size = number<br>      type = string<br>    })<br>  })</pre> | <pre>{<br>  "dali": {<br>    "size": 100,<br>    "type": "azurefiles"<br>  },<br>  "debug": {<br>    "size": 100,<br>    "type": "blobnfs"<br>  },<br>  "dll": {<br>    "size": 100,<br>    "type": "blobnfs"<br>  },<br>  "lz": {<br>    "size": 100,<br>    "type": "blobnfs"<br>  },<br>  "sasha": {<br>    "size": 100,<br>    "type": "blobnfs"<br>  }<br>}</pre> | no |
| <a name="input_admin_services_storage_account_settings"></a> [admin\_services\_storage\_account\_settings](#input\_admin\_services\_storage\_account\_settings) | Settings for admin services storage account. | <pre>object({<br>    authorized_ip_ranges = map(string)<br>    delete_protection    = bool<br>    replication_type     = string<br>    subnet_ids           = map(string)<br>  })</pre> | <pre>{<br>  "authorized_ip_ranges": {},<br>  "delete_protection": false,<br>  "replication_type": "ZRS",<br>  "subnet_ids": {}<br>}</pre> | no |
| <a name="input_data_storage_config"></a> [data\_storage\_config](#input\_data\_storage\_config) | Data plane config for HPCC. | <pre>object({<br>    internal = object({<br>      blob_nfs = object({<br>        data_plane_count = number<br>        storage_account_settings = object({<br>          authorized_ip_ranges = map(string)<br>          delete_protection    = bool<br>          replication_type     = string<br>          subnet_ids           = map(string)<br>        })<br>      })<br>      hpc_cache = object({<br>        cache_update_frequency = string<br>        dns = object({<br>          zone_name                = string<br>          zone_resource_group_name = string<br>        })<br>        resource_provider_object_id = string<br>        size                        = string<br>        storage_account_data_planes = list(object({<br>          container_id         = string<br>          container_name       = string<br>          id                   = number<br>          resource_group_name  = string<br>          storage_account_id   = string<br>          storage_account_name = string<br>        }))<br>        subnet_id = string<br>      })<br>    })<br>    external = object({<br>      blob_nfs = list(object({<br>        container_id         = string<br>        container_name       = string<br>        id                   = string<br>        resource_group_name  = string<br>        storage_account_id   = string<br>        storage_account_name = string<br>      }))<br>      hpc_cache = list(object({<br>        id     = string<br>        path   = string<br>        server = string<br>      }))<br>      hpcc = list(object({<br>        name = string<br>        planes = list(object({<br>          local  = string<br>          remote = string<br>        }))<br>        service = string<br>      }))<br>    })<br>  })</pre> | <pre>{<br>  "external": null,<br>  "internal": {<br>    "blob_nfs": {<br>      "data_plane_count": 1,<br>      "storage_account_settings": {<br>        "authorized_ip_ranges": {},<br>        "delete_protection": false,<br>        "replication_type": "ZRS",<br>        "subnet_ids": {}<br>      }<br>    },<br>    "hpc_cache": null<br>  }<br>}</pre> | no |
| <a name="input_enable_node_tuning"></a> [enable\_node\_tuning](#input\_enable\_node\_tuning) | Enable node tuning daemonset (only needed once per AKS cluster). | `bool` | `true` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Adds default environment variables for all components. | `map(string)` | `{}` | no |
| <a name="input_helm_chart_overrides"></a> [helm\_chart\_overrides](#input\_helm\_chart\_overrides) | Helm chart values, in yaml format, to be merged last. | `string` | `""` | no |
| <a name="input_helm_chart_timeout"></a> [helm\_chart\_timeout](#input\_helm\_chart\_timeout) | Helm timeout for hpcc chart. | `number` | `600` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Version of the HPCC Helm Chart to use. | `string` | `"8.6.20"` | no |
| <a name="input_hpcc_container"></a> [hpcc\_container](#input\_hpcc\_container) | HPCC container information (if version is set to null helm chart version is used). | <pre>object({<br>    image_name = string<br>    image_root = string<br>    version    = string<br>  })</pre> | n/a | yes |
| <a name="input_hpcc_container_registry_auth"></a> [hpcc\_container\_registry\_auth](#input\_hpcc\_container\_registry\_auth) | Registry authentication for HPCC container. | <pre>object({<br>    password = string<br>    username = string<br>  })</pre> | `null` | no |
| <a name="input_install_blob_csi_driver"></a> [install\_blob\_csi\_driver](#input\_install\_blob\_csi\_driver) | Install blob-csi-drivers on the cluster. | `bool` | `true` | no |
| <a name="input_ldap_config"></a> [ldap\_config](#input\_ldap\_config) | LDAP settings for dali and esp services. | <pre>object({<br>    dali = object({<br>      adminGroupName      = string<br>      filesBasedn         = string<br>      groupsBasedn        = string<br>      hpcc_admin_password = string<br>      hpcc_admin_username = string<br>      ldap_admin_password = string<br>      ldap_admin_username = string<br>      ldapAdminVaultId    = string<br>      resourcesBasedn     = string<br>      sudoersBasedn       = string<br>      systemBasedn        = string<br>      usersBasedn         = string<br>      workunitsBasedn     = string<br>    })<br>    esp = object({<br>      adminGroupName      = string<br>      filesBasedn         = string<br>      groupsBasedn        = string<br>      ldap_admin_password = string<br>      ldap_admin_username = string<br>      ldapAdminVaultId    = string<br>      resourcesBasedn     = string<br>      sudoersBasedn       = string<br>      systemBasedn        = string<br>      usersBasedn         = string<br>      workunitsBasedn     = string<br>    })<br>    ldap_server = string<br>  })</pre> | `null` | no |
| <a name="input_ldap_tunables"></a> [ldap\_tunables](#input\_ldap\_tunables) | Tunable settings for LDAP. | <pre>object({<br>    cacheTimeout                  = number<br>    checkScopeScans               = bool<br>    ldapTimeoutSecs               = number<br>    maxConnections                = number<br>    passwordExpirationWarningDays = number<br>    sharedCache                   = bool<br>  })</pre> | <pre>{<br>  "cacheTimeout": 5,<br>  "checkScopeScans": true,<br>  "ldapTimeoutSecs": 131,<br>  "maxConnections": 10,<br>  "passwordExpirationWarningDays": 10,<br>  "sharedCache": true<br>}</pre> | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region in which to create resources. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace where resources will be created. | <pre>object({<br>    name   = string<br>    labels = map(string)<br>  })</pre> | <pre>{<br>  "labels": {<br>    "name": "hpcc"<br>  },<br>  "name": "hpcc"<br>}</pre> | no |
| <a name="input_node_tuning_container_registry_auth"></a> [node\_tuning\_container\_registry\_auth](#input\_node\_tuning\_container\_registry\_auth) | Registry authentication for node tuning containers. | <pre>object({<br>    password = string<br>    username = string<br>  })</pre> | `null` | no |
| <a name="input_node_tuning_containers"></a> [node\_tuning\_containers](#input\_node\_tuning\_containers) | URIs for containers to be used by node tuning submodule. | <pre>object({<br>    busybox = string<br>    debian  = string<br>  })</pre> | <pre>{<br>  "busybox": "docker.io/library/busybox:1.34",<br>  "debian": "docker.io/library/debian:bullseye-slim"<br>}</pre> | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to deploy resources. | `string` | n/a | yes |
| <a name="input_roxie_config"></a> [roxie\_config](#input\_roxie\_config) | Configuration for Roxie(s). | <pre>list(object({<br>    disabled       = bool<br>    name           = string<br>    nodeSelector   = map(string)<br>    numChannels    = number<br>    prefix         = string<br>    replicas       = number<br>    serverReplicas = number<br>    services = list(object({<br>      name        = string<br>      servicePort = number<br>      listenQueue = number<br>      numThreads  = number<br>      visibility  = string<br>    }))<br>    topoServer = object({<br>      replicas = number<br>    })<br>  }))</pre> | <pre>[<br>  {<br>    "disabled": true,<br>    "name": "roxie",<br>    "nodeSelector": {},<br>    "numChannels": 2,<br>    "prefix": "roxie",<br>    "replicas": 2,<br>    "serverReplicas": 0,<br>    "services": [<br>      {<br>        "listenQueue": 200,<br>        "name": "roxie",<br>        "numThreads": 30,<br>        "servicePort": 9876,<br>        "visibility": "local"<br>      }<br>    ],<br>    "topoServer": {<br>      "replicas": 1<br>    }<br>  }<br>]</pre> | no |
| <a name="input_spill_volume_size"></a> [spill\_volume\_size](#input\_spill\_volume\_size) | Size of spill volume to be created (in GB). | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to Azure resources. | `map(string)` | `{}` | no |
| <a name="input_thor_config"></a> [thor\_config](#input\_thor\_config) | Configuration for Thor(s). | <pre>list(object({<br>    disabled = bool<br>    eclAgentResources = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    keepJobs = string<br>    managerResources = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    maxGraphs        = number<br>    maxJobs          = number<br>    name             = string<br>    nodeSelector     = map(string)<br>    numWorkers       = number<br>    numWorkersPerPod = number<br>    prefix           = string<br>    workerMemory = object({<br>      query      = string<br>      thirdParty = string<br>    })<br>    workerResources = object({<br>      cpu    = string<br>      memory = string<br>    })<br>  }))</pre> | <pre>[<br>  {<br>    "disabled": true,<br>    "eclAgentResources": {<br>      "cpu": 1,<br>      "memory": "2G"<br>    },<br>    "keepJobs": "none",<br>    "managerResources": {<br>      "cpu": 1,<br>      "memory": "2G"<br>    },<br>    "maxGraphs": 2,<br>    "maxJobs": 4,<br>    "name": "thor",<br>    "nodeSelector": {},<br>    "numWorkers": 2,<br>    "numWorkersPerPod": 1,<br>    "prefix": "thor",<br>    "workerMemory": {<br>      "query": "3G",<br>      "thirdParty": "500M"<br>    },<br>    "workerResources": {<br>      "cpu": 3,<br>      "memory": "4G"<br>    }<br>  }<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
