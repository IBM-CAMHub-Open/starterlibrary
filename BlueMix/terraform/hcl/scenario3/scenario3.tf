provider "ibm" {
  version = "~> 1.14.0"  
}

module "camtags" {
  source = "../Modules/camtags"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "first_hostname" {
  description = "Hostname of the first virtual instance (small flavor) to be deployed"
  default     = "debian-small"
}

variable "second_hostname" {
  description = "Hostname of the second virtual instance (medium flavor) to be deployed"
  default     = "debian-medium"
}

variable "domain" {
  description = "VM domain"
}

variable "os_reference_code_debian" {
  type = "string"
  description = "Operating system image id / template that should be used when creating the virtual image"
  default = "DEBIAN_9_64"
}

#data "ibm_compute_image_template" "debian_8_6_64" {
#  name = "100GB - Debian / Debian / 8.0.0-64 Minimal for VSI"
#}

# This will create a new SSH key that will show up under the \
# Devices>Manage>SSH Keys in the SoftLayer console.
resource "ibm_compute_ssh_key" "orpheus_public_key" {
  label      = "Orpheus Public Key"
  public_key = "${var.public_ssh_key}"
}

# Create a new virtual guest using image "Debian"
resource "ibm_compute_vm_instance" "debian_small_virtual_guest" {
  hostname                 = "${var.first_hostname}"
  #image_id                 = "${data.ibm_compute_image_template.debian_8_6_64.id}"
  os_reference_code        = "${var.os_reference_code_debian}"
  domain                   = "${var.domain}"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  user_metadata            = "{\"value\":\"newvalue\"}"
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.orpheus_public_key.id}"]
  tags                     = ["${module.camtags.tagslist}"]
}

# Create a new virtual guest using image "Debian"
resource "ibm_compute_vm_instance" "debian_medium_virtual_guest" {
  hostname                 = "${var.second_hostname}"
  #image_id                 = "${data.ibm_compute_image_template.debian_8_6_64.id}"
  os_reference_code        = "${var.os_reference_code_debian}"  
  domain                   = "${var.domain}"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = true
  cores                    = 2
  memory                   = 4096
  user_metadata            = "{\"value\":\"newvalue\"}"
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.orpheus_public_key.id}"]
  tags                     = ["${module.camtags.tagslist}"]
}

output "debian_small_vm_ip" {
  value = "Public : ${ibm_compute_vm_instance.debian_small_virtual_guest.ipv4_address}"
}

output "debian_medium_vm_ip" {
  value = "Public : ${ibm_compute_vm_instance.debian_medium_virtual_guest.ipv4_address}"
}
