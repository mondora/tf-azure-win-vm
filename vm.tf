resource "azurerm_resource_group" "vmrg" {
  name       = "${var.environment}-${var.region}-vm-rg"
  location   = "${var.region}"
  depends_on = ["azurerm_subnet.vm-subnet"]

  tags {
    env = "${var.environment}"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.environment}${var.region}stor"
  location                 = "${var.region}"
  resource_group_name      = "${azurerm_resource_group.vmrg.name}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"
  depends_on               = ["azurerm_resource_group.vmrg"]

  tags {
    env = "${var.environment}"
  }
}

resource "azurerm_availability_set" "avset" {
  name                         = "${var.environment}${var.region}avset"
  location                     = "${var.region}"
  resource_group_name          = "${azurerm_resource_group.vmrg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  depends_on                   = ["azurerm_resource_group.vmrg"]

  tags {
    env = "${var.environment}"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic${count.index}"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.vmrg.name}"
  count               = 2
  depends_on          = ["azurerm_resource_group.vmrg", "azurerm_lb_rule.lb-rule", "azurerm_lb_nat_rule.nat"]

  ip_configuration {
    name                                    = "ipconfig${count.index}"
    subnet_id                               = "${azurerm_subnet.vm-subnet.id}"
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend-pool.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.nat.*.id, count.index)}"]
  }

  tags {
    env = "${var.environment}"
  }
}

resource "azurerm_managed_disk" "datadisk" {
  name                 = "${var.environment}-${var.region}-datadisk-${count.index}"
  location             = "${var.region}"
  resource_group_name  = "${azurerm_resource_group.vmrg.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "30"
  count                = 2
  depends_on           = ["azurerm_resource_group.vmrg"]
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.environment}-${var.region}-vm-${count.index}"
  location              = "${var.region}"
  resource_group_name   = "${azurerm_resource_group.vmrg.name}"
  count                 = 2
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  depends_on            = ["azurerm_managed_disk.datadisk", "azurerm_network_interface.nic", "azurerm_storage_account.storage"]

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name              = "${var.environment}-${var.region}-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.environment}-${var.region}-datadisk-${count.index}"
    managed_disk_id   = "${element(azurerm_managed_disk.datadisk.*.id, count.index)}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "30"
    create_option     = "Attach"
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.hostname}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = "${var.key_data}"
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
  }

  tags {
    env = "${var.environment}"
  }
}
