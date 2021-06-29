variable namespace {
    description = "Namespace to deply HPCC to"
    type = string
}

variable name {
    description = "App name"
    type = string
}

variable create_namespace {
    description = "Create the namespace if it doesn't exist"
    type = bool
    default = false
}

variable hpcc_helm_version {
    description = "Version of the HPCC Helm Chart to use "
    type = string
    default = "8.2.0-rc2"
}

variable hpcc_system_values {
    description = "List of HPCC helm config yaml values - raw yaml"
    type = list(string)
}

variable hpcc_storage_values {
    description = "List of HPCC Storage helm config yaml values - raw yaml"
    type = list(string)
}