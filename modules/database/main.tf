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
    virtual_network_subnet_ids =  var.sub-id
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
  virtual_network_name = var.vnet-name
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
  virtual_network_id    = var.vnet-id
  resource_group_name   = var.resource_group_name
}

resource "azurerm_mysql_flexible_server" "example" {
  name                   = "wprs-mysql"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = "med"
  administrator_password = "abc123..."
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
  value = "OFF"
}