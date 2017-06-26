provider "ibmcloud" {
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

data "ibmcloud_infra_image_template" "debian_8_6_64" {
    name = "100GB - Debian / Debian / 8.0.0-64 Minimal for VSI"
}

# This will create a new SSH key that will show up under the \
# Devices>Manage>SSH Keys in the SoftLayer console.
resource "ibmcloud_infra_ssh_key" "orpheus_public_key" {
    label = "Orpheus Public Key"
    public_key = "${var.public_ssh_key}"
}

# Create a new virtual guest using image "Debian"
resource "ibmcloud_infra_virtual_guest" "debian_small_virtual_guest" {
    hostname = "${var.first_hostname}"
    image_id = "${data.ibmcloud_infra_image_template.debian_8_6_64.id}"
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
    ssh_key_ids = ["${ibmcloud_infra_ssh_key.orpheus_public_key.id}"]
}

# Create a new virtual guest using image "Ubuntu"
resource "ibmcloud_infra_virtual_guest" "ubuntu_medium_virtual_guest" {
    hostname = "${var.second_hostname}"
    #image_id = "${data.ibmcloud_infra_image_template.ubuntu_16_04_01_64.id}"
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
    ssh_key_ids = ["${ibmcloud_infra_ssh_key.orpheus_public_key.id}"]
}

