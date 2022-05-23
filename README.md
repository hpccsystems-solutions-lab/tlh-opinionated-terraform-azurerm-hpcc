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

---

## Terraform

| **Version** |
| :---------- |
| `>= 1.0.0`  |

## Providers

| **Name**   | **Version** |
| :--------- | :---------- |
| azurerm    | >=2.85.0    |
| helm       | >=2.1.1     |
| kubernetes | >=2.5.0     |
| random     | >=2.3.0     |

## Inputs

| **Variable**                              | **Description**                                                      | **Type**                                             | **Default** | **Required** |
| :---------------------------------------- | :------------------------------------------------------------------- | :--------------------------------------------------- | :--------   | :----------- |
| `admin_services_node_selector`            | Node selector for admin services pods.                               | `map(map(string)` [_(see appendix a)_](#Appendix-A)  | `{}`        | `no`         |
| `admin_services_storage_account_settings` | Settings for admin services storage account.                         | `object()` [_(see appendix b)_](#Appendix-B)         | `{}`        | `no`         |
| `admin_services_storage_size`             | PV sizes for admin service planes (storage billed only as consumed). | `object()` [_(see appendix c)_](#Appendix-C)         | `{}`        | `no`         |
| `data_storage_config`                     | HPCC Data storage config.                                            | `object()` [_(see appendix d)_](#Appendix-D)         | `nil`       | `yes`        |
| `enable_node_tuning`                      | Enable node tuning daemonset (only needed once per AKS cluster).     | `bool`                                               | `true`      | `no`         |
| `environment_variables`                   | Adds default environment variables for all components.               | `map(string)`                                        | `{}`        | `no`         |
| `helm_chart_overrides`                    | Helm chart values, in yaml format, to be merged last.                | `string`                                             | `nil`       | `no`         |
| `helm_chart_timeout`                      | Helm timeout for hpcc chart in seconds.                              | `number`                                             | `600`       | `no`         |
| `helm_chart_version`                      | Version of the HPCC Helm Chart to use.                               | `string`                                             | `8.6.16`    | `no`         |
| `hpcc_container`                          | HPCC container information.                                          | `object()` [_(see appendix s)_](#Appendix-S)         | `nil`       | `yes`        |
| `hpcc_container_registry_auth`            | Registry authentication for HPCC container.                          | `object()` [_(see appendix t)_](#Appendix-T)         | `nil`       | `no`         |
| `install_blob_csi_driver`                 | Install blob-csi-drivers on the cluster.                             | `bool`                                               | `true`      | `no`         |
| `ldap_config`                             | LDAP settings for dali and esp services.                             | `object()` [_(see appendix u)_](#Appendix-U)         | `nil`       | `no`         |
| `ldap_tunables`                           | Tunable settings for LDAP.                                           | `string`                                             | `nil`       | `no`         |
| `location`                                | Azure region in which to create resources.                           | `string`                                             | `nil`       | `yes`        |
| `namespace`                               | Kubernetes namespace where resources will be created.                | `object()` [_(see appendix y)_](#Appendix-Y)         | `hpcc`      | `no`         |
| `node_tuning_containers`                  | URIs for containers to be used by node tuning submodule.             | `object()` [_(see appendix z)_](#Appendix-Z)         | `{}`        | `no`         |
| `node_tuning_container_registry_auth`     | Registry authentication for node tuning containers.                  | `object()` [_(see appendix aa)_](#Appendix-AA)       | `{}`        | `no`         |
| `resource_group_name`                     | The name of the resource group to deploy resources.                  | `string`                                             | `nil`       | `yes`        |
| `roxie_config`                            | Settings for roxie service.                                          | `list(object())` [_(see appendix bb)_](#Appendix-BB) | `disabled`  | `no`         |
| `spill_volume_size`                       | Storage config for hpcc.                                             | `string`                                             | `nil`       | `no`         |
| `thor_config`                             | Settings for thor service.                                           | `list(object())` [_(see appendix ee)_](#Appendix-EE) | `disabled`  | `no`         |
| `tags`                                    | Tags to be applied to Azure resources.                               | `map(string)`                                        | `{}`        | `no`         |

### Appendix B

`admin_services_storage_account_settings` object specification

| **Variable**           | **Description**                 | **Type**      | **Required** |
| :--------------------- | :------------------------------ | :------------ | :----------- |
| `authorized_ip_ranges` | CIDRs/IPs allowed to access.    | `map(string)` | `yes`        |
| `delete_protection`    | Enable AzureRM management lock. | `bool`        | `yes`        |
| `replication_type`     | Storage account Replication.    | `string`      | `yes`        |
| `subnet_ids`           | Service endpoints to create.    | `map(string)` | `yes`        |

### Appendix C

`admin_services_storage_size` object specification

| **Variable**           | **Description**                            | **Type**                                     | **Required** |
| :----------------------| :----------------------------------------- | :------------------------------------------- | :----------- |
| `dali`                 | Storage type/size for dali storage plane.  | `object() [_(see appendix D)_](#Appendix-d)` | `yes`        |
| `debug`                | Storage type/size for debug storage plane. | `object() [_(see appendix D)_](#Appendix-d)` | `yes`        |
| `dll`                  | Storage type/size for dll storage plane.   | `object() [_(see appendix D)_](#Appendix-d)` | `yes`        |
| `lz`                   | Storage type/size for lz storage plane.    | `object() [_(see appendix D)_](#Appendix-d)` | `yes`        |
| `sasha`                | Storage type/size for sasha storage plane. | `object() [_(see appendix D)_](#Appendix-d)` | `yes`        |

### Appendix D

`admin_services_storage_size.<service>` object specification

| **Variable** | **Description**                           | **Type** | **Required** |
| :----------- :-----------------------------------------  | :------- | :----------- |
| `size`       | Size in gigabytes.                        | `number` | `yes`        |
| `type`       | Storage type ("azurefiles" or "blobnfs"). | `string` | `yes`        |

### Appendix E

`data_storage_config` object specification

| **Variable** | **Description**                                     | **Type**                                     | **Required** |
| :----------- | :-------------------------------------------------- | :------------------------------------------- | :----------- |
| `internal`   | HPCC data storage provisioned by this module.       | `object()` [_(see appendix f)_](#Appendix-F) | `no`         |
| `external`   | HPCC data storage provisioned outside this module.  | `object()` [_(see appendix n)_](#Appendix-N) | `yes`        |

### Appendix F

`data_storage_config.internal` object specification

| **Variable** | **Description**                  | **Type**                                     | **Required** |
| :----------- | :------------------------------- | :------------------------------------------- | :----------- |
| `blob_nfs`   | Blob NFS storage configuration.  | `object()` [_(see appendix g)_](#Appendix-G) | `no`         |
| `hpc_cache`  | HPC Cache storage configuration. | `object()` [_(see appendix i)_](#Appendix-I) | `no`         |

### Appendix G

`data_storage_config.internal.blob_nfs` object specification

| **Variable**               | **Description**                                                | **Type**                                     | **Required** |
| :------------------------- | :------------------------------------------------------------- | :------------------------------------------- | :----------- |
| `data_plane_count`         | Number of data planes (storage accounts/containers) to create. | `number`                                     | `yes`        |
| `storage_account_settings` | Storage account settings for data planes.                      | `object()` [_(see appendix h)_](#Appendix-H) | `yes`        |

### Appendix H

`data_storage_config.internal.blob_nfs.storage_account_settings` object specification

| **Variable**           | **Description**                 | **Type**      | **Required** |
| :----------------------| :------------------------------ | :------------ | :----------- |
| `authorized_ip_ranges` | CIDRs/IPs allowed to access.    | `map(string)` | `yes`        |
| `delete_protection`    | Enable AzureRM management lock. | `bool`        | `yes`        |
| `replication_type`     | Storage account Replication.    | `string`      | `yes`        |
| `subnet_ids`           | Service endpoints to create.    | `map(string)` | `yes`        |

### Appendix I

`data_storage_config.internal.hpc_cache` object specification

| **Variable**                  | **Description**                                                             | **Type**                                          | **Required** |
| :---------------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------ | :----------- |
| `dns`                         | DNS information.                                                            | `object()` [_(see appendix j)_](#Appendix-J)      | `yes`        |
| `resource_provider_object_id` | Object ID of HPC Cache resource provider.                                   | `string` [(_see appendix k)_](#Appendix-K)        | `yes`        |
| `size`                        | Size of HPC Cache (small, medium, large).                                   | `string`                                          | `yes`        |
| `storage_targets`             | Storage target information.                                                 | `map(object())` [_(see appendix l)_](#Appendix-L) | `yes`        |
| `subnet_id`                   | Virtual network subnet id where HPC Cache will be placed.                   | `string`                                          | `yes`        |

### Appendix J

`data_storage_config.internal.hpc_cache.dns` object specification

| **Variable**               | **Description**                           | **Type** | **Required** |
| :------------------------- | :---------------------------------------- | :------- | :----------- |
| `zone_name`                | DNS zone name.                            | `string` | `yes`        |
| `zone_resource_group_name` | Resource group name containting dns zone. | `string` | `yes`        |

### Appendix K

`data_storage_config.internal.hpc_cache.resource_provider_object_id` sourcing recommendation

This code can be used to retrieve the service principal info:

```
data "azuread_service_principal" "hpc_cache_resource_provider" {
  display_name = "HPC Cache Resource Provider"
}
```

The input would then look like this:

```
resource_provider_object_id = data.azuread_service_principal.hpc_cache_resource_provider.object_id
```

### Appendix L

`data_storage_config.internal.hpc_cache.storage_targets` object specification

| **Variable**                  | **Description**                                                | **Type** | **Required** |
| :---------------------------- | :------------------------------------------------------------- | :--------| :----------- |
| `cache_update_frequency`      | Cache update frequency (never, 30s, 3h).                       | `string` | `yes`        |
| `storage_account_data_planes` | Storage account data planes. [_(see appendix m)_](#Appendix-M) | `string` | `yes`        |

### Appendix M

`data_storage_config.internal.hpc_cache.storage_targets.storage_account_data_planes` object specification

| **Variable**           | **Description**                      | **Type** | **Required** |
| :----------------------| :----------------------------------- | :--------| :----------- |
| `container_id`         | Storage account container id.        | `string` | `yes`        |
| `container_name`       | Storage account container name.      | `string` | `yes`        |
| `id`                   | Data plane id.                       | `number` | `yes`        |
| `resource_group_name`  | Storage account resource group name. | `string` | `yes`        |
| `storage_account_id`   | Storage account id.                  | `string` | `yes`        |
| `storage_account_name` | Storage account name.                | `string` | `yes`        |

### Appendix N

`data_storage_config.external` object specification

| **Variable** | **Description**                  | **Type**                                           | **Required** |
| :----------- | :------------------------------- | :------------------------------------------------- | :----------- |
| `blob_nfs`   | Blob NFS storage configuration.  | `list(object())` [_(see appendix o)_](#Appendix-O) | `no`        |
| `hpc_cache`  | HPC Cache storage configuration. | `list(object())` [_(see appendix p)_](#Appendix-P) | `no`        |
| `hpcc`       | Remote HPCC data configuration.  | `list(object())` [_(see appendix q)_](#Appendix-Q) | `no`        |

### Appendix O

`data_storage_config.external.blob_nfs` object specification

| **Variable**           | **Description**                      | **Type** | **Required** |
| :--------------------- | :----------------------------------- | :--------| :----------- |
| `container_id`         | Storage account container id.        | `string` | `yes`        |
| `container_name`       | Storage account container name.      | `string` | `yes`        |
| `id`                   | Data plane id.                       | `number` | `yes`        |
| `resource_group_name`  | Storage account resource group name. | `string` | `yes`        |
| `storage_account_id`   | Storage account id.                  | `string` | `yes`        |
| `storage_account_name` | Storage account name.                | `string` | `yes`        |

### Appendix P

`data_storage_config.external.hpc_cache` object specification

| **Variable** | **Description**                                                      | **Type** | **Required** |
| :----------- | :------------------------------------------------------------------- | :--------| :----------- |
| `id`         | Data plane id.                                                       | `string` | `yes`        |
| `path`       | HPC Cache path.                                                      | `string` | `yes`        |
| `server`     | HPC Cache URI (must be Azure DNS record to ensure full performance). | `number` | `yes`        |

### Appendix Q

`data_storage_config.external.hpcc` object specification

| **Variable** | **Description**                 | **Type**                                           | **Required** |
| :----------- | :------------------------------ | :------------------------------------------------- | :----------- |
| `name`       | Remote HPCC cluster identifier. | `string`                                           | `yes`        |
| `planes`     | Data plane information.         | `list(object())` [_(see appendix r)_](#Appendix-R) | `yes`        |
| `service`    | Remote HPCC service URI.        | `string`                                           | `yes`        |

### Appendix R

`data_storage_config.external.hpcc.planes` object specification

| **Variable** | **Description**         | **Type** | **Required** |
| :----------- | :---------------------- | :--------| :----------- |
| `local`      | Local data plane name.  | `string` | `yes`        |
| `remote`     | Remote data plane name. | `string` | `yes`        |

### Appendix S

`hpcc_container` object specification

| **Variable** | **Description**                                       | **Type** | **Required** |
| :----------- | :---------------------------------------------------- | :------- | :----------- |
| `image_name` | Name of container image.                              | `string` | `yes`        |
| `image_root` | URI to image root.                                    | `string` | `yes`        |
| `version`    | Container version (null will use helm chart version). | `string` | `yes`        |

### Appendix T

`hpcc_container_registry_auth` object specification

| **Variable** | **Description**                                       | **Type** | **Required** |
| :----------- | :---------------------------------------------------- | :------- | :----------- |
| `password`   | Password/API key.                                     | `string` | `yes`        |
| `username`   | Username.                                             | `string` | `yes`        |

### Appendix U

`ldap_config` object specification

| **Variable**  | **Description**             | **Type**                                     | **Required** |
| :------------ | :-------------------------- | :------------------------------------------- | :----------- |
| `dali`        | Dali service LDAP settings. | `object()` [_(see appendix v)_](#Appendix-V) | `yes`        |
| `esp`         | ESP service LDAP settings.  | `object()` [_(see appendix w)_](#Appendix-W) | `yes`        |
| `ldap_server` | LDAP server address.        | `string`                                     | `yes`        |

### Appendix V

`ldap_config.dali` object specification

| **Variable**          | **Description**                                               | **Type** | **Required** |
| :-------------------- | :------------------------------------------------------------ | :------- | :----------- |
| `adminGroupName`      | LDAP adminGroupName.                                          | `string` | `yes`        |
| `filesBasedn`         | LDAP filesBasedn.                                             | `string` | `yes`        |
| `groupsBasedn`        | LDAP groupsBasedn.                                            | `string` | `yes`        |
| `hpcc_admin_password` | LDAP hpcc admin password (kubernetes secret will be created). | `string` | `yes`        |
| `hpcc_admin_username` | LDAP hpcc admin username (kubernetes secret will be created). | `string` | `yes`        |
| `ldap_admin_password` | LDAP ldap admin password (kubernetes secret will be created). | `string` | `yes`        |
| `ldap_admin_username` | LDAP ldap admin username (kubernetes secret will be created). | `string` | `yes`        |
| `ldapAdminSecretKey`  | LDAP ldapAdminSecretKey.                                      | `string` | `yes`        |
| `ldapAdminVaultId`    | LDAP ldapAdminVaultId.                                        | `string` | `yes`        |
| `resourcesBasedn`     | LDAP resourcesBasedn.                                         | `string` | `yes`        |
| `sudoersBasedn`       | LDAP sudoersBasedn.                                           | `string` | `yes`        |
| `systemBasedn`        | LDAP systemBasedn.                                            | `string` | `yes`        |
| `usersBasedn`         | LDAP usersBasedn.                                             | `string` | `yes`        |
| `workunitsBasedn`     | LDAP workunitsBasedn.                                         | `string` | `yes`        |

### Appendix W

`ldap_config.esp` object specification

| **Variable**          | **Description**                                               | **Type** | **Required** |
| :-------------------- | :------------------------------------------------------------ | :------- | :----------- |
| `adminGroupName`      | LDAP adminGroupName.                                          | `string` | `yes`        |
| `filesBasedn`         | LDAP filesBasedn.                                             | `string` | `yes`        |
| `groupsBasedn`        | LDAP groupsBasedn.                                            | `string` | `yes`        |
| `ldap_admin_password` | LDAP ldap admin password (kubernetes secret will be created). | `string` | `yes`        |
| `ldap_admin_username` | LDAP ldap admin username (kubernetes secret will be created). | `string` | `yes`        |
| `ldapAdminSecretKey`  | LDAP ldapAdminSecretKey.                                      | `string` | `yes`        |
| `ldapAdminVaultId`    | LDAP ldapAdminVaultId.                                        | `string` | `yes`        |
| `resourcesBasedn`     | LDAP resourcesBasedn.                                         | `string` | `yes`        |
| `sudoersBasedn`       | LDAP sudoersBasedn.                                           | `string` | `yes`        |
| `systemBasedn`        | LDAP systemBasedn.                                            | `string` | `yes`        |
| `usersBasedn`         | LDAP usersBasedn.                                             | `string` | `yes`        |
| `workunitsBasedn`     | LDAP workunitsBasedn.                                         | `string` | `yes`        |

### Appendix X

`ldap_tunables` object specification

| **Variable**                    | **Description**          | **Type** | **Default** | **Required** |
| :------------------------------ | :----------------------- | :------- | :---------- | :----------- |
| `cacheTimeout`                  | LDAP adminGroupName.     | `number` | `5`         | `yes`        |
| `checkScopeScans`               | LDAP filesBasedn.        | `bool`   | `true`      | `yes`        |
| `ldapTimeoutSecs`               | LDAP groupsBasedn.       | `number` | `131`       | `yes`        |
| `maxConnections`                | LDAP hpccAdminSecretKey. | `number` | `10`        | `yes`        |
| `passwordExpirationWarningDays` | LDAP ldapAdminSecretKey. | `number` | `10`        | `yes`        |
| `sharedCache`                   | LDAP ldapAdminVaultId.   | `bool`   | `true`      | `yes`        |

### Appendix Y

`namespace` object specification

| **Variable** | **Description**                         | **Type**      | **Default**       | **Required** |
| :----------- | :-------------------------------------- | :------------ | :---------------- | :----------- |
| `namespace`  | Namespace name.                         | `string`      | `hpcc`            | `yes`        |
| `labels`     | Lables to be applied to the namespace'. | `map(string)` | `{name = "hpcc"}` | `no`         |

### Appendix Z

`node_tuning_containers` object specification

| **Variable** | **Description**                             | **Type** | **Default**                              | **Required** |
| :----------- | :------------------------------------------ | :------- | :--------------------------------------- | :----------- |
| `busybox`    | URI for busybox container.                  | `string` | `docker.io/library/busybox:1.34`         | `yes`        |
| `debian`     | URI for debian container (slim preferred)'. | `string` | `docker.io/library/debian:bullseye-slim` | `yes`        |

### Appendix AA

`node_tuning_container_registry_auth` object specification

| **Variable** | **Description**                                       | **Type** | **Required** |
| :----------- | :---------------------------------------------------- | :------- | :----------- |
| `password`   | Password/API key.                                     | `string` | `yes`        |
| `username`   | Username.                                             | `string` | `yes`        |

### Appendix BB

`roxie_config` object specification

| **Variable**    | **Description**                  | **Type**                                             | **Required** |
| :-------------- | :------------------------------- | :--------------------------------------------------- | :----------- |
| `disabled`      | Disable this roxie config.       | `bool`                                               | `yes`        |
| `name`          | Name of roxie config.            | `string`                                             | `yes`        |
| `nodeSelector`  | NodeSelector for pod placement.  | `map(string)`                                        | `yes`        |
| `numChannels`   | Number of pods per cluster.      | `number`                                             | `yes`        |
| `prefix`        | Root directory for access plane. | `string`                                             | `yes`        |
| `replicas`      | Number of replicas per channel.  | `number`                                             | `yes`        |
| `serverReplicas`| Number of replica sets.          | `number`                                             | `yes`        |
| `services`      | Service configs.                 | `list(object())` [_(see appendix bb)_](#Appendix-BB) | `yes`        |
| `topoServer`    | TopoServer config.               | `object()` [_(see appendix cc)_](#Appendix-CC)       | `yes`        |

### Appendix CC

`roxie_config.services` object specification

| **Variable**  | **Description**      | **Type** | **Required** |
| :------------ | :------------------- | :------- | :----------- |
| `name`        | Service name.        | `string` | `yes`        |
| `servicePort` | Service port.        | `number` | `yes`        |
| `listenQueue` | Listen queue length. | `number` | `yes`        |
| `numThreads`  | Number of threads.   | `number` | `yes`        |
| `visability`  | Service visability.  | `string` | `yes`        |

### Appendix DD

`roxie_config.topoServer` object specification

| **Variable** | **Description**     | **Type**      | **Required** |
| :----------- | :------------------ | :------------ | :----------- |
| `replicas`   | Number of replicas. | `number`      | `yes`        |

### Appendix EE

`thor_config` object specification

| **Variable**        | **Description**                  | **Type**                                       | **Required** |
| :------------------ | :------------------------------- | :--------------------------------------------- | :----------- |
| `disabled`          | Disable this Thor config.        | `bool`                                         | `yes`        |
| `eclAgentResources` | ECL Agent resource settings.     | `object()` [_(see appendix ff)_](#Appendix-FF) | `yes`        |
| `keepJobs`          | Persist pods after job failure.  | `string`   ("_none_" or "_all_")               | `yes`        |
| `managerResources`  | Manager resource settings.       | `object()` [_(see appendix gg)_](#Appendix-EE) | `yes`        |
| `maxGraphs`         | Maximum number of graphs.        | `number`                                       | `yes`        |
| `maxJobs`           | Maximum number of jobs in queue. | `number`                                       | `yes`        |
| `name`              | Name of Thor config.             | `string`                                       | `yes`        |
| `nodeSelector`      | NodeSelector for pod placement.  | `map(string)`                                  | `yes`        |
| `numWorkersPerPod`  | Number of workers per pod.       | `number`                                       | `yes`        |
| `numWorkers`        | Number of Thor workers.          | `number`                                       | `yes`        |
| `prefix`            | Root directory for access plane. | `string`                                       | `yes`        |
| `workerMemory`      | Worker memory settings.          | `object()` [_(see appendix hh)_](#Appendix-HH) | `yes`        |
| `workerResources`   | Worker resource settings.        | `object()` [_(see appendix ii)_](#Appendix-II) | `yes`        |

### Appendix FF

`thor_config.eclAgentResources` object specification

| **Variable** | **Description** | **Type** | **Required** |
| :----------- | :-------------- | :------- | :----------- |
| `cpu`        | CPU config.     | `string` | `yes`        |
| `memory`     | Memory config.  | `string` | `yes`        |

### Appendix GG

`thor_config.managerResources` object specification

| **Variable** | **Description** | **Type** | **Required** |
| :----------- | :-------------- | :------- | :----------- |
| `cpu`        | CPU config.     | `string` | `yes`        |
| `memory`     | Memory config.  | `string` | `yes`        |

### Appendix HH

`thor_config.workerMemory` object specification

| **Variable** | **Description**            | **Type** | **Required** |
| :----------- | :------------------------- | :------- | :----------- |
| `query`      | Query memory config.       | `string` | `yes`        |
| `thirdParty` | Third party memory config. | `string` | `yes`        |

### Appendix II 

`thor_config.workerResources` object specification

| **Variable** | **Description** | **Type**      | **Required** |
| :----------- | :-------------- | :------------ | :----------- |
| `cpu`        | CPU config.     | `string`      | `yes`        |
| `memory`     | Memory config.  | `string`      | `yes`        |
