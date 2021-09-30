provider "azurerm" {
  version = ">=2.21.0"
  features {}
}

locals{
  functionapp_zip_location = "deploy/functionapp.zip"
}
resource "azurerm_resource_group" "rg" {
    name = "${var.prefix}-${var.environment}"
    location = "${var.location}"
}

resource "azurerm_storage_account" "storage" {
    name = "${random_string.storage_name.result}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    account_tier = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_storage_container" "deployments" {
    name = "function-releases"
    storage_account_name = "${azurerm_storage_account.storage.name}"
    container_access_type = "private"
}

resource "azurerm_storage_blob" "appcode" {
    name = "functionapp.zip"
    storage_account_name = "${azurerm_storage_account.storage.name}"
    storage_container_name = "${azurerm_storage_container.deployments.name}"
    type = "Block"
    source = "${var.functionapp}"
}

resource "azurerm_application_insights" "app_insight" {
  name                = "${var.prefix}-appinsights"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  application_type    = "web"

  tags = {
    "hidden-link:${azurerm_resource_group.rg.id}/providers/Microsoft.Web/sites/${var.prefix}func" = "Resource"
  }

}
resource "azurerm_app_service_plan" "asp" {
    name = "${var.prefix}-plan"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    kind = "FunctionApp"
    sku {
        tier = "Dynamic"
        size = "Y1"
    }
}

# resource "azurerm_function_app" "functions" {
#     name = "${var.prefix}-${var.environment}"
#     location = "${var.location}"
#     resource_group_name = "${azurerm_resource_group.rg.name}"
#     app_service_plan_id = "${azurerm_app_service_plan.asp.id}"
#     storage_account_name       = "${azurerm_storage_account.storage.name}"
#     storage_account_access_key = "${azurerm_storage_account.storage.primary_access_key}"
#     version                    = "~3"
#     os_type                    = "linux"
#     # storage_connection_string = "${azurerm_storage_account.storage.primary_connection_string}"
#      app_settings = {
#         https_only = true
#         WEBSITE_RUN_FROM_PACKAGE = "1"
#         FUNCTIONS_WORKER_RUNTIME = "python"
#         HASH = "${base64encode(filesha256("${var.functionapp}"))}"
#         APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.app_insight.instrumentation_key}"
#         WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.deployments.name}/${azurerm_storage_blob.appcode.name}${data.azurerm_storage_account_sas.sas.sas}"
#     }
#      site_config {
#         linux_fx_version= "Python|3.8"        
#         ftps_state = "Disabled"
#     }
#     #   Enable if you need Managed Identity
#   identity {
#     type = "SystemAssigned"
#   }

# }

resource "azurerm_function_app" "functions" {
    name                      = "${var.prefix}-${var.environment}"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.rg.name}"
    app_service_plan_id       = "${azurerm_app_service_plan.asp.id}"
    storage_connection_string = "${azurerm_storage_account.storage.primary_connection_string}"
    os_type                   = "linux"

    # app_settings = {
    #     https_only = true
    #     FUNCTIONS_WORKER_RUNTIME = "python"
    #     WEBSITE_NODE_DEFAULT_VERSION = "~10"
    #     FUNCTION_APP_EDIT_MODE = "readonly"
    #     HASH = "${base64encode(filesha256("${var.functionapp}"))}"
    #     WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.deployments.name}/${azurerm_storage_blob.appcode.name}${data.azurerm_storage_account_sas.sas.sas}"
    # }
}

data "archive_file" "zipit" {
  type        = "zip"
  source_file = "deploy/functionapp.py"
  output_path = "${local.functionapp_zip_location}"
}