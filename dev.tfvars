address_space       = "10.16.0.0/16"
resource_group_name = "my-rg"
besoin = "1"
my_public_ip        = "213.248.108.232"

sub_number = {
    type= "list"
    default = ["0","1"]
}
services = {
  mywp = {
    size                            = "Standard_F2"
    admin_username                  = "adminuser"
    admin_password                  = "abc123***"
    disable_password_authentication = false
    custom_data_path                = "templates/script.sh"
    wordpress_version               = "6.3.1"
    source_image_reference = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }
  }
}
storage_conf = {
  mywp = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
    is_hns_enabled           = true
    nfsv3_enabled            = true
    container = {
      name                  = "medcntnr"
      container_access_type = "private"
    }
  }
}
