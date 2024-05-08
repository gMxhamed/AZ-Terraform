module "network" {
  source = "./modules/network"
  address_space = var.address_space
  location = var.location
  sub_number = var.sub_number
  resource_group_name = var.resource_group_name
  besoin = var.besoin
}

module "lb" {
  source = "./modules/lb"
  location = var.location
  resource_group_name = var.resource_group_name
  lb-subid = module.network.pub-ip[1]
}

module "vmss" {
  source = "./modules/vmss"
  location = var.location
  resource_group_name = var.resource_group_name
  services = var.services
  storage_conf = var.storage_conf
  besoin = var.besoin
  vmss-subid = module.network.sub-id[0]
  lb-backend-id = [module.lb.lb-backend-id]
  nfs-endp = module.database.nfs-endp
}

module "database" {
  source = "./modules/database"
  resource_group_name = var.resource_group_name
  location = var.location
  services = var.services
  storage_conf = var.storage_conf
  besoin = var.besoin
  my_public_ip = var.my_public_ip
  vnet-name = module.network.vnet-name
  vnet-id = module.network.vnet-id
  sub-id = [module.network.sub-id[0]]
}

module "budget" {
  source = "./modules/budget"
  resource_group_name = var.resource_group_name
  rg-id = module.network.rg-id
}

/*resource "null_resource" "serverspec-test" {
  provisioner "local-exec" {
    command = <<-EOT
      rspec
    EOT
  }
}

/*
resource "azurerm_monitor_action_group" "rg-act" {
  name                = "rgact"
  resource_group_name = var.resource_group_name
  short_name          = "rga"
}

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "rg-budget"
  resource_group_id = module.network.rg-id
  amount     = 10
  time_grain = "Monthly"

  time_period {
    start_date = "2024-04-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_monitor_action_group.rg-act.id,
      ]
    }

  }

  notification {
    enabled        = true
    threshold      = 90.0
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"

    contact_emails = ["mohammed.guendouz@ynov.com"]

    contact_groups = [
      azurerm_monitor_action_group.rg-act.id,
    ]

    contact_roles = [
      "Owner",
    ]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = ["mohammed.guendouz@ynov.com"]
  }
}

# -----------------------configuration du Load Balancer--------------------------------------------------------------------------------------------------
/*
resource "azurerm_lb" "lb" {
  name                = "my-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-ipconf"
    public_ip_address_id = module.network.pub-ip[1]
  }
}

resource "azurerm_lb_backend_address_pool" "adress-pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-pool"
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule"
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.adress-pool.id]

}
*/
# -----------------------configuration du VMSS--------------------------------------------------------------------------------------------------

/*
resource "azurerm_network_interface" "NIC" {
  count = var.besoin
  name = "my-nic${count.index}"
  location = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name = "my-ipconf${count.index}"
    private_ip_address_allocation = "Dynamic"
    subnet_id = module.network.sub-id[0]
  }
}

resource "azurerm_network_security_group" "sec-grp" {
  name                = "wp-secgrp"
  location            = var.location
  resource_group_name = var.resource_group_name

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
  backend_address_pool_id = azurerm_lb_backend_address_pool.adress-pool.id
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
    nfs_endpoint      =  azurerm_storage_account.wpdata[each.key].primary_blob_host
    blob_storage_name = "wp-strg"
    wordpress_version = var.services[each.key].wordpress_version
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
      subnet_id                              = module.network.sub-id[0]
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.adress-pool.id]
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
*/
# -----------------------configuration du compte de stockage--------------------------------------------------------------------------------------------------

/*
resource "azurerm_storage_account" "wpdata" {
  for_each                 = var.storage_conf
  name                     = each.key
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_conf[each.key].account_tier
  account_replication_type = var.storage_conf[each.key].account_replication_type
  account_kind             = var.storage_conf[each.key].account_kind
  is_hns_enabled           = var.storage_conf[each.key].is_hns_enabled
  nfsv3_enabled            = var.storage_conf[each.key].nfsv3_enabled

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids =  [module.network.sub-id[0]]
    ip_rules                   = [var.my_public_ip]
  }
}

resource "azurerm_storage_container" "container" {
  for_each              = var.storage_conf
  name                  = var.storage_conf[each.key].container.name
  storage_account_name  = azurerm_storage_account.wpdata[each.key].name
  container_access_type = var.storage_conf[each.key].container.container_access_type
  depends_on            = [azurerm_storage_account.wpdata]
}


resource "azurerm_subnet" "strg-sub" {
  name                 = "strg-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = module.network.vnet-name
  address_prefixes     = ["10.16.10.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "dns.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet-dns" {
  name                  = "dnsVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = module.network.vnet-id
  resource_group_name   = var.resource_group_name
}

resource "azurerm_mysql_flexible_server" "example" {
  name                   = "mysql-fs"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.strg-sub.id
  private_dns_zone_id    = azurerm_private_dns_zone.dns.id
  sku_name               = "GP_Standard_D2ds_v4"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.vnet-dns]
}

resource "azurerm_mysql_flexible_database" "example" {
  name                = "wordpress"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.example.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.example.name
  value               = "OFF"
}
*/