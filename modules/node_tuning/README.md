# node-tuning

## Overview

This module is designed to install the node tuning daemonset for use with the [terraform-azurerm-hpcc](https://github.com/LexisNexis-RBA/terraform-azurerm-hpcc) module.

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

| **Variable**         | **Description**                                          | **Type**                                     | **Default** | **Required** |
| :------------------- | :------------------------------------------------------- | :------------------------------------------- | :--------   | :----------- |
| `create_namespace`   | Create kubernetes namespace.                             | `bool`                                       | `hpcc-data` | `no`        |
| `namespace`          | Kubernetes namespace in which to install the helm chart. | `object()` [_(see appendix a)_](#Appendix-A) | `nil`       | `no`         |

### Appendix A

`namespace` object specification

| **Variable** | **Description**                         | **Type**      | **Required** |
| :----------- | :-------------------------------------- | :------------ | :----------- |
| `namespace`  | Namespace name.                         | `string`      | `yes`        |
| `labels`     | Lables to be applied to the namespace'. | `map(string)` | `yes`        |