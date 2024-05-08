output "nfs-endp" {
  value =[for host in azurerm_storage_account.wpdata : host.primary_blob_host] //azurerm_storage_account.wpdata[mywp].primary_blob_host
}