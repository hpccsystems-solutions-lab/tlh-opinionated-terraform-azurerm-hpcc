locals {
    hpcc_secrets = {    
        elastic-credentials = {
            name = "elastic-credentials"
            namespace = "elasticsearch"
            type = "Opaque"
            data = {
                username = "elastic"
                password = random_password.elastic_password.result
            }
        }
    }
}