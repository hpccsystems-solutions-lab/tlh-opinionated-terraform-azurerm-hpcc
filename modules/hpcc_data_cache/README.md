# hpcc-data-storage

## Overview

This module is designed to provide a simple and opinionated way to build HPC Cache targets for use with the [terraform-azurerm-hpcc](https://github.com/LexisNexis-RBA/terraform-azurerm-hpcc) module.

---

## Support Policy

Support and use of this module.

---

## Requirements

## Usage

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
| random     | >=2.3.0     |

## Inputs

| **Variable**                  | **Description**                                                             | **Type**                                          | **Default** | **Required** |
| :---------------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------ | :--------   | :----------- |
| `dns`                         | DNS information.                                                            | `object()` [_(see appendix a)_](#Appendix-A)      | `hpcc-data` | `yes`        |
| `location`                    | Azure region in which to create resources.                                  | `string`                                          | `nil`       | `yes`        |
| `name`                        | HPC Cache name.                                                             | `string`                                          | `nil`       | `yes`         |
| `resource_group_name`         | The name of the resource group to deploy resources.                         | `string`                                          | `nil`       | `yes`        |
| `resource_provider_object_id` | Object ID of HPC Cache resource provider [(_see appendix b_)](#Appendix-C). | `string`                                          | `nil`       | `yes`        |
| `size`                        | Size of HPC Cache (small, medium, large).                                   | `string`                                          | `nil`       | `yes`        |
| `storage_targets`             | Storage target information.                                                 | `map(object())` [_(see appendix c)_](#Appendix-C) | `{}`        | `yes`        |
| `subnet_id`                   | Virtual network subnet id where HPC Cache will be placed.                   | `string`                                          | `yes`       | `yes`        |
| `tags`                        | Tags to be applied to Azure resources.                                      | `map(string)`                                     | `{}`        | `no`         |

### Appendix A

`dns` object specification

| **Variable**               | **Description**                           | **Type** | **Required** |
| :------------------------- | :---------------------------------------- | :------- | :----------- |
| `zone_name`                | DNS zone name.                            | `string` | `yes`        |
| `zone_resource_group_name` | Resource group name containting dns zone. | `string` | `yes`        |

### Appendix B

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

### Appendix C

`storage_targets` object specification

| **Variable**                  | **Description**                                                | **Type** | **Required** |
| :---------------------------- | :------------------------------------------------------------- | :--------| :----------- |
| `cache_update_frequency`      | Cache update frequency (never, 30s, 3h).                       | `string` | `yes`        |
| `storage_account_data_planes` | Storage account data planes. [_(see appendix d)_](#Appendix-D) | `string` | `yes`        |

### Appendix D

`storage_account_data_planes` object specification

| **Variable**           | **Description**                      | **Type** | **Required** |
| :----------------------| :----------------------------------- | :--------| :----------- |
| `container_id`         | Storage account container id.        | `string` | `yes`        |
| `container_name`       | Storage account container name.      | `string` | `yes`        |
| `id`                   | Data plane id.                       | `number` | `yes`        |
| `resource_group_name`  | Storage account resource group name. | `string` | `yes`        |
| `storage_account_id`   | Storage account id.                  | `string` | `yes`        |
| `storage_account_name` | Storage account name.                | `string` | `yes`        |

---

## Outputs

| **Variable**          | **Description**                                       | **Type**                                          |
| :-------------------- | :-----------------------------------------------------| :------------------------------------------------ |
| `data_planes`         | Data plane object for use with HPCC terraform module. | `map(object())` [_(see appendix 1)_](#Appendix-1) |
| `fqdn`                | Azure DNS fqdn for HPC Cache..                        | `string`                                          |
| `hpc_cache`           | HPC Cache terraform object.                           | `object()`                                        |
| `hpc_cache_id`        | HPC Cache id.                                         | `string`                                          |
| `hpc_cache_name`      | HPC Cache name.                                       | `string`                                          |
| `resource_group_name` | Resource group name comtaining the HPC Cache.         | `string`                                          |

### Appendix 1

`data_planes` object specification

| **Variable** | **Description**                        | **Type** |
| :----------- | :------------------------------------- | :--------|
| `id`         | Data plane id.                         | `string` |
| `path`       | HPC Cache path.                        | `string` |
| `server`     | HPC Cache URI (Azure DNS record fqdn). | `number` |
