# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017.
#
#################################################################

provider "ibm" {
  version = "~> 0.5"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "first_hostname" {
  description = "Hostname of the first virtual instance (small flavor) to be deployed"
  default = "debian-small"
}

variable "second_hostname" {
  description = "Hostname of the second virtual instance (medium flavor) to be deployed"
  default = "ubuntu-medium"
}

data "ibm_compute_image_template" "debian_8_6_64" {
    name = "100GB - Debian / Debian / 8.0.0-64 Minimal for VSI"
}

# This will create a new SSH key that will show up under the \
# Devices>Manage>SSH Keys in the SoftLayer console.
resource "ibm_compute_ssh_key" "orpheus_public_key" {
    label = "Orpheus Public Key"
    public_key = "${var.public_ssh_key}"
}

# Create a new virtual guest using image "Debian"
resource "ibm_compute_vm_instance" "debian_small_virtual_guest" {
    hostname = "${var.first_hostname}"
    image_id = "${data.ibm_compute_image_template.debian_8_6_64.id}"
    domain = "cam.ibm.com"
    datacenter = "${var.datacenter}"
    network_speed = 10
    hourly_billing = true
    private_network_only = false
    cores = 1
    memory = 1024
    user_metadata = "{\"value\":\"newvalue\"}"
    dedicated_acct_host_only = false
    local_disk = false
    ssh_key_ids = ["${ibm_compute_ssh_key.orpheus_public_key.id}"]
}

# Create a new virtual guest using image "Ubuntu"
resource "ibm_compute_vm_instance" "ubuntu_medium_virtual_guest" {
    hostname = "${var.second_hostname}"
    #image_id = "${data.ibm_compute_image_template.ubuntu_16_04_01_64.id}"
    os_reference_code="UBUNTU_16_64"
    domain = "cam.ibm.com"
    datacenter = "${var.datacenter}"
    network_speed = 10
    hourly_billing = true
    private_network_only = false
    cores = 2
    memory = 4096
    user_metadata = "{\"value\":\"newvalue\"}"
    dedicated_acct_host_only = false
    local_disk = false
    ssh_key_ids = ["${ibm_compute_ssh_key.orpheus_public_key.id}"]
}

