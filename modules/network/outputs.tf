output "sub-id" {
  value = azurerm_subnet.sub.*.id
}
output "rg-id" {
  value = azurerm_resource_group.rg.id
}
output "pub-ip" {
  value = azurerm_public_ip.publc-ip.*.id
}
output "vnet-name" {
  value = azurerm_virtual_network.ntwrk.name
}

/*output "vnet-name" {
  value = for [ value in azurerm_virtual_network.ntwrk.name : name]
}
*/
output "vnet-id" {
  value = azurerm_virtual_network.ntwrk.id
}