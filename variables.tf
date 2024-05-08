variable "location" {
  type        = string
  default     = "France Central"
}
variable "resource_group_name" {
  type = string
}
variable "address_space" {
  type        = string
  description = "Vnet CIDR"
}
variable "sub_number" {
  type        = any
}
variable "besoin" {
  type = any
}
variable "services" {
  type = any
}
variable "storage_conf" {
  type = any
}
variable "my_public_ip" {
}
