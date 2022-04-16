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

| **Variable**              | **Description**                                          | **Type**                                     | **Default** | **Required** |
| :------------------------ | :------------------------------------------------------- | :------------------------------------------- | :--------   | :----------- |
| `containers`              | URIs for containers to be used by node tuning submodule. | `object()` [_(see appendix a)_](#Appendix-A) | `{}`        | `no`         |
| `container_registry_auth` | Registry authentication for node tuning containers.      | `object()` [_(see appendix b)_](#Appendix-B) | `{}`        | `no`         |
| `create_namespace`        | Create kubernetes namespace.                             | `bool`                                       | `true`      | `no`         |
| `namespace`               | Kubernetes namespace in which to install the helm chart. | `object()` [_(see appendix c)_](#Appendix-C) | `nil`       | `no`         |
 
### Appendix A

`containers` object specification

| **Variable** | **Description**                             | **Type** | **Default**                              | **Required** |
| :----------- | :------------------------------------------ | :------- | :--------------------------------------- | :----------- |
| `busybox`    | URI for busybox container.                  | `string` | `docker.io/library/busybox:1.34`         | `yes`        |
| `debian`     | URI for debian container (slim preferred)'. | `string` | `docker.io/library/debian:bullseye-slim` | `yes`        |

### Appendix B

`container_registry_auth` object specification

| **Variable** | **Description**                                       | **Type** | **Required** |
| :----------- | :---------------------------------------------------- | :------- | :----------- |
| `password`   | Password/API key.                                     | `string` | `yes`        |
| `username`   | Username.                                             | `string` | `yes`        |

### Appendix C

`namespace` object specification

| **Variable** | **Description**                         | **Type**      | **Default**                   | **Required** |
| :----------- | :-------------------------------------- | :------------ | :---------------------------- | :----------- |
| `namespace`  | Namespace name.                         | `string`      | `hpcc-node-tuning`            | `yes`        |
| `labels`     | Lables to be applied to the namespace'. | `map(string)` | `{name = "hpcc-node-tuning"}` | `yes`        |
