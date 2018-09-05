resource "azurerm_resource_group" "netrg" {
  name     = "${var.environment}-${var.region}-vnet-rg"
  location = "${var.region}"
  tags {
    service = "${var.service}"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-${var.region}-vnet"
  location            = "${var.region}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.netrg.name}"
  depends_on          = ["azurerm_resource_group.netrg"]

  tags {
    env = "${var.service}"
  }
}

resource "azurerm_subnet" "apgw-subnet" {
  name                 = "${var.service}-${var.region}-apgw-subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.netrg.name}"
  address_prefix       = "${var.lb_subnet}"
  depends_on           = ["azurerm_virtual_network.vnet"]
}

resource "azurerm_subnet" "vm-subnet" {
  name                 = "${var.service}-${var.environment}-${var.region}-vm-subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.netrg.name}"
  address_prefix       = "${var.vm_subnet}"
  depends_on           = ["azurerm_virtual_network.vnet"]
}
