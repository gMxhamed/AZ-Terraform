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