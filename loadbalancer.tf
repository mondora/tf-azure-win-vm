resource "azurerm_resource_group" "lbrg" {
  name       = "${var.environment}-${var.region}-lb-rg"
  location   = "${var.region}"
  depends_on = ["azurerm_virtual_network.vnet"]

  tags {
    env = "${var.environment}"
  }
}

resource "azurerm_public_ip" "lbpip" {
  name                         = "${var.environment}-${var.region}-ip"
  location                     = "${var.region}"
  resource_group_name          = "${azurerm_resource_group.lbrg.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.environment}-${var.region}-terraform"
  depends_on                   = ["azurerm_resource_group.lbrg"]

  tags {
    env = "${var.environment}"
  }
}

resource "azurerm_lb" "lb" {
  name                = "${var.environment}-${var.region}-lb"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.lbrg.name}"
  depends_on          = ["azurerm_public_ip.lbpip"]

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEndIP"
    public_ip_address_id = "${azurerm_public_ip.lbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend-pool" {
  resource_group_name = "${azurerm_resource_group.lbrg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "BackendPool1"
  depends_on          = ["azurerm_lb.lb"]
}

resource "azurerm_lb_nat_rule" "nat" {
  resource_group_name            = "${azurerm_resource_group.lbrg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "RDP-VM-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "2000${count.index + 1}"
  backend_port                   = 3389
  frontend_ip_configuration_name = "LoadBalancerFrontEndIP"
  count                          = 2
  depends_on                     = ["azurerm_lb.lb"]
}

resource "azurerm_lb_probe" "lb-probe" {
  resource_group_name = "${azurerm_resource_group.lbrg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 30
  number_of_probes    = 3
  depends_on          = ["azurerm_lb.lb"]
}

resource "azurerm_lb_rule" "HTTP-lb-rule" {
  resource_group_name            = "${azurerm_resource_group.lbrg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEndIP"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend-pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb-probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb-probe"]
}

resource "azurerm_lb_rule" "HTTPS-lb-rule" {
  resource_group_name            = "${azurerm_resource_group.lbrg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEndIP"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend-pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb-probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb-probe"]
}
