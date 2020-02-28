data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "vm_network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "vm_image_template" {
  name          = var.vm_image_template
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

variable "allow_unverified_ssl" {
  description = "Communication with vSphere server with self signed certificate"
  default     = "true"
}

variable "vm_name" {
  type = string
}

variable "vm_ipv4_address" {
  type = string
}

variable "vm_memory" {
  type = string
}

variable "vm_vcpu" {
  type = string
}

variable "vm_disk_size" {
  type = string
}

variable "vm_disk_keep_on_remove" {
  type    = string
  default = "false"
}

variable "vm_ipv4_gateway" {
  type = string
}

variable "vm_ipv4_netmask" {
  type = string
}

variable "vm_domain_name" {
  type = string
}

variable "network" {
  type = string
}

variable "adapter_type" {
  type = string
}

variable "vm_folder" {
  type = string
}

variable "dns_servers" {
  type = list(string)
}

variable "dns_suffixes" {
  type = list(string)
}

variable "vm_clone_timeout" {
  description = "The timeout, in minutes, to wait for the virtual machine clone to complete."
}

variable "datacenter" {
  type = string
}

variable "resource_pool" {
  type = string
}

variable "vm_image_template" {
  type = string
}

variable "vm_os_user" {
  type = string
}

variable "vm_os_password" {
  type = string
}

variable "datastore" {
  type = string
}

variable "vm_os_private_ssh_key" {
  type = string
}

variable "vm_os_public_ssh_key" {
  type = string
}

