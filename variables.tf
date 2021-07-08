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
    description = "Version of the HPCC Helm Chart to use"
    type = string
    default = "8.2.2-rc1"
}

variable hpcc_config {
    description = "Config options to pass to the values template for hpcc"
    type = object(
        {
            storage = map(object({
                volume_size = string
                path_prefix = string
                pvc_name = string
            }))
        }
    )
}