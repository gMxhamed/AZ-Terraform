resource "azurerm_network_interface" "NIC" {
  count = var.besoin
  name = "my-nic${count.index}"
  location = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name = "my-ipconf${count.index}"
    private_ip_address_allocation = "Dynamic"
    subnet_id = var.vmss-subid
  }
}

resource "azurerm_network_security_group" "sec-grp" {
  name                = "wp-secgrp"
  location            = var.location
  resource_group_name = "my-rg"

  security_rule {
    name                       = "all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "pool_assoc" {
  for_each                = var.services
  network_interface_id    = azurerm_network_interface.NIC[0].id
  ip_configuration_name   = azurerm_network_interface.NIC[0].ip_configuration[0].name
  backend_address_pool_id = var.lb-backend-id[0]
}

resource "azurerm_linux_virtual_machine_scale_set" "VMSS" {
  for_each                        = var.services
  name                            = title(each.key)
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku                             = var.services[each.key].size
  admin_username                  = var.services[each.key].admin_username
  admin_password                  = var.services[each.key].admin_password
  disable_password_authentication = var.services[each.key].disable_password_authentication
  custom_data = base64encode(templatefile("${path.module}/script.sh", {
    nfs_endpoint      =  var.nfs-endp[0]
    blob_storage_name = "wp-strg"
    wordpress_version = "6.3.1" //var.services[each.key].wordpress_version
  }))

  source_image_reference {
    publisher = var.services[each.key].source_image_reference.publisher
    offer     = var.services[each.key].source_image_reference.offer
    sku       = var.services[each.key].source_image_reference.sku
    version   = var.services[each.key].source_image_reference.version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = "nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.sec-grp.id

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.vmss-subid
      load_balancer_backend_address_pool_ids = var.lb-backend-id

    }
  }
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
}

resource "azurerm_monitor_autoscale_setting" "vmss_set" {
  for_each            = var.services
  name                = "vmss-set"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.VMSS[each.key].id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.VMSS[each.key].id
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 50
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "dim"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.VMSS[each.key].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 50
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["mohammed.guendouz@ynov.com"]
    }
  }
}
