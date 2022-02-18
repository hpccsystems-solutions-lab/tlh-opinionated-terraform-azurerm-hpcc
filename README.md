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


<!--- END_TF_DOCS --->