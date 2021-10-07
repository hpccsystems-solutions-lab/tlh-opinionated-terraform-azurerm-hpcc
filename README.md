# HPCC Systems Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard HPCC Systems Platforms and utilizes the [terraform-azurerm-aks](https://github.com/LexisNexis-RBA/terraform-azurerm-aks) module. This module takes a set of configuration options and creates a fully functional HPCC Systems deployment.

---

## Support Policy

Support and use of this module.

---

## Requirements

Since this module utilizes the [terraform-azurerm-aks](https://github.com/LexisNexis-RBA/terraform-azurerm-aks) module, be sure to consult its requirements [
[documentation](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/docs).

In particular, carefully review networking and DNS requirements.

---

## Usage

This module is designed to provide a standard, opinonated, but configurable, deployment of the HPCC Systems platform on AKS.

See [examples](/examples) for general usage. 

---

## Terraform

| Version   |
|-----------|
| >= 0.14.8 |

## Providers

| Name       | Version   |
|------------|-----------|
| azurerm    | >= 2.72.0 |
| helm       | >= 2.1.1  |
| kubernetes | ~> 1.13   |
| random     | >= 2.3.0  |

## Inputs

| **Variable**                       | **Description**                                                                                                           | **Type**                                        | **Default**       | **Required** |
|:-----------------------------------|:--------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------|:------------------|:------------:|
| `cluster_name`                     | Name of the AKS cluster, also used as a prefix in names of related resources.                                             | `string`                                        | `nil`             | `yes`        |
| `cluster_version`                  | The Kubernetes minor version. Version `1.21` supported.                                                                   | `string`                                        | `"1.21"`          | `no`         |
| `core_services_config`             | Configuration options for core platform services                                                                          | `any` _(see aks documentation)_                 | `nil`             | `yes`        |
| `hpcc_helm_version`                | Version of HPCC Systems Helm chart to use.                                                                                | `string`                                        | `8.2.10-1`        | `no`         |
| `hpcc_namespace`                   | Namespace to deploy the HPCC Helm chart.                                                                                  | `string`                                        | `hpcc`            | `no`         |
| `hpcc_replica_config`              | Map of number of replicas to configure for each hpcc component service.                                                   | `map(number)`                                   | `hpcc`            | `no`         |
| `hpcc_storage_config`              | Key value pair of storage container names and their sizes to create. Persistent volumes are created from these names.     | `map(object)`                                   | `{}`             | `no`         |
| `location`                         | Azure region in which to build resources.                                                                                 | `string`                                        | `nil`             | `yes`        |
| `pod_cidr`                         | CIDR range for pod IP addresses when using the `kubenet` network plugin.                                                  | `string`                                        | `"100.65.0.0/16"` | `no`         |
| `resource_group_name`              | Name of the Resource Group to deploy the AKS Kubernetes service into, must already exist.                                 | `string`                                        | `nil`             | `yes`        |
| `storage_account_delete_protection`| Flag to enable delete protection on the HPCC storage account.                                                             | `bool`                                          | `true`            | `no`         |
| `storage_network_subnet_ids`       | List of network Subnet IDs to give storage access.                                                                        | `list(string)`                                  | `nil`             | `yes`        |
| `tags`                             | Tags to be applied to cloud resources.                                                                                    | `map(string)`                                   | `{}`              | `no`         |