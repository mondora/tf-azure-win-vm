provider "azurerm" {}

variable "environment" {}
variable "region" {}
variable "address_space" {}

variable "lb_subnet" {}

variable "vm_subnet" {}

variable "storage_account_tier" {}

variable "storage_replication_type" {}

variable "vm_size" {}

variable "image_publisher" {}

variable "image_offer" {}

variable "image_sku" {}

variable "image_version" {}

variable "hostname" {}

variable "admin_username" {}

variable "key_data" {}
