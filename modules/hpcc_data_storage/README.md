# hpcc-data-storage

## Overview

This module is designed to provide a simple and opinionated way to build storage accounts and containers for use with the [terraform-azurerm-hpcc](https://github.com/LexisNexis-RBA/terraform-azurerm-hpcc) module.

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

| **Variable**                 | **Description**                                                   | **Type**                                     | **Default** | **Required** |
| :--------------------------- | :---------------------------------------------------------------- | :------------------------------------------- | :--------   | :----------- |
| `container_name`             | Name of container to create within storage accounts.              | `string`                                     | `hpcc-data` |     `no`     |
| `data_plane_count`           | Number of data planes/storage accounts to be created.             | `number`                                     | `1`         |     `no`     |
| `location`                   | Azure region in which to create resources.                        | `string`                                     | `nil`       |     `yes`    |
| `resource_group_name`        | The name of the resource group to deploy resources.               | `string`                                     | `nil`       |     `yes`    |
| `storage_account_name_prefix`| Prefix for storage account name (leave null for auto-generation). | `string`                                     | `nil`       |     `no`     |
| `storage_account_settings`   | Storage account settings.                                         | `object()` [_(see appendix a)_](#Appendix-A) | `{}`        |     `no`     |
| `tags`                       | Tags to be applied to Azure resources.                            | `map(string)`                                | `{}`        |     `no`     |

### Appendix A

`storage_account_settings` object specification

| **Variable**           | **Description**                 | **Type**      | **Required** |
| :----------------------| :------------------------------ | :------------ | :----------- |
| `authorized_ip_ranges` | CIDRs/IPs allowed to access.    | `map(string)` | `yes`        |
| `delete_protection`    | Enable AzureRM management lock. | `bool`        | `yes`        |
| `replication_type`     | Storage account Replication.    | `string`      | `yes`        |
| `subnet_ids`           | Service endpoints to create.    | `map(string)` | `yes`        |