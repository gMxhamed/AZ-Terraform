resource "azurerm_lb" "lb" {
  name                = "my-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-ipconf"
    public_ip_address_id = var.lb-subid
  }
}

resource "azurerm_lb_backend_address_pool" "adress-pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-pool"
}

resource "azurerm_lb_rule" "lb_rule_0" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule-0"
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.adress-pool.id]
}
resource "azurerm_lb_rule" "lb_rule_1" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule-1"
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 3000
  backend_port                   = 3000
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.adress-pool.id]
}
resource "azurerm_lb_rule" "lb_rule_2" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule-2"
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.adress-pool.id]
}