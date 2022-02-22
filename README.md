# HPCC Systems Terraform Module

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

2.  This module supports the Jfrog setup to deliver the hpcc systems images.
    *   You need to request Viewer access to required project in [Jfrog](https://useast.jfrog.lexisnexisrisk.com/)
---

## Usage

This module is designed to provide a standard, opinonated, but configurable, deployment of the HPCC Systems platform on AKS.

See [examples](/examples) for general usage. 

---

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.0.0 |
| azurerm | >=2.85.0 |
| helm | >=2.1.1 |
| kubernetes | >=2.5.0 |
| random | >=2.3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >=2.85.0 |
| helm | >=2.1.1 |
| kubernetes | >=2.5.0 |
| random | >=2.3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aks\_principal\_id | AKS Principal ID | `string` | n/a | yes |
| blob-csi-driver | Determines if the blob-csi-drivers are to be installed for the cluster. | `bool` | `true` | no |
| hpc\_cache\_dns\_name | n/a | <pre>object({<br>    zone_name                = string<br>    zone_resource_group_name = string<br>  })</pre> | n/a | yes |
| hpc\_cache\_name | n/a | `string` | n/a | yes |
| hpcc\_helm\_version | Version of the HPCC Helm Chart to use | `string` | `"8.6.0"` | no |
| hpcc\_namespace | HPCC Namespace | `string` | `"hpcc"` | no |
| hpcc\_replica\_config | HPCC component scaling | `map(number)` | `{}` | no |
| hpcc\_storage\_account\_name | Storage account name for hpcc | `string` | `""` | no |
| hpcc\_storage\_account\_resource\_group\_name | Storage account resource group name for hpcc | `string` | `""` | no |
| hpcc\_storage\_config | Storage config for hpcc | <pre>map(object({<br>    container_name = string<br>    size           = string<br>    })<br>  )</pre> | n/a | yes |
| jfrog\_registry | values to set as secrets for JFrog repo access | <pre>object({<br>    username   = string<br>    password   = string # API Token<br>    image_root = string<br>    image_name = string<br>  })</pre> | n/a | yes |
| location | Azure region in which to build resources. | `string` | n/a | yes |
| resource\_group\_name | The name of the Resource Group to deploy the AKS cluster service to, must already exist. | `string` | n/a | yes |
| storage\_account\_authorized\_ip\_ranges | Map of authorized CIDRs / IPs | `map(string)` | n/a | yes |
| storage\_account\_delete\_protection | Protect storage from deletion | `bool` | `true` | no |
| storage\_network\_subnet\_ids | The network ids to grant storage access | `list(string)` | `null` | no |
| tags | Tags to be applied to cloud resources. | `map(string)` | `{}` | no |

## Outputs

No output.

<!--- END_TF_DOCS --->