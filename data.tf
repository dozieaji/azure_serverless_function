data "azurerm_storage_account_sas" "sas" {
    connection_string = "${azurerm_storage_account.storage.primary_connection_string}"
    https_only = true
    start = "2021-08-01"
    expiry = "2022-12-31"
    resource_types {
        object = true
        container = false
        service = false
    }
    services {
        blob = true
        queue = false
        table = false
        file = false
    }
    permissions {
        read = true
        write = false
        delete = false
        list = false
        add = false
        create = false
        update = false
        process = false
    }
}
