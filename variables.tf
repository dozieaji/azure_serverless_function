variable "prefix" {
    type = string
    default = "pytfunction"
}

variable "location" {
    type = string
    default = "westus"
}

variable "environment" {
    type = string
    default = "dev"
}

variable "functionapp" {
    type = string
    default = "./deploy/functionapp.zip"
}

resource "random_string" "storage_name" {
    length = 16
    upper = false
    lower = true
    number = true
    special = false
}