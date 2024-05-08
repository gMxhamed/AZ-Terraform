resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "ntwrk" {
    name = "my-first-network"
    address_space = [var.address_space]
    location = azurerm_resource_group.rg.location
    resource_group_name = var.resource_group_name
    tags = {
    "Environment" = "VNET"
  }
}

/*  
     ***********   subnet0: privé  ***********
           
     ***********   subnet1: public  ***********
*/
resource "azurerm_subnet" "sub" {
  count                = length(var.sub_number)
  name = "my-subnet${count.index}"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.ntwrk.name
  address_prefixes = tolist(["10.16.${count.index}.0/24"])
  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_public_ip" "publc-ip" {
  count                = length(var.sub_number)
  name = "my-ip${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.location
  allocation_method = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat-gtw" {
  name = "my-natgtw"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_nat_gateway_public_ip_association" "nat-asso" {
  count = var.besoin
  public_ip_address_id = azurerm_public_ip.publc-ip[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat-gtw.id
}

resource "azurerm_subnet_nat_gateway_association" "sub-nat-asso" {
  count = var.besoin
  nat_gateway_id = azurerm_nat_gateway.nat-gtw.id
  subnet_id = azurerm_subnet.sub[count.index].id
}
