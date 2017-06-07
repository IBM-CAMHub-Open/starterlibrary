#################################################################
# Terraform template that will deploy an VM with Node.js only
#
# Version: 1.0
#
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

#########################################################
# Define the ibmcloud provider
#########################################################

provider "ibmcloud" {
}

#########################################################
# Define the variables
#########################################################

variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "hostname" {
  description = "Hostname of the virtual instance to be deployed"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

##############################################################
# Create public key in Devices>Manage>SSH Keys in SL console
##############################################################

resource "ibmcloud_infra_ssh_key" "cam_public_key" {
    label = "CAM Public Key"
    public_key = "${var.public_ssh_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibmcloud_infra_ssh_key" "temp_public_key" {
  label = "Temp Public Key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################
# Define the module to create a server and install nodejs
##############################################################
module "install_nodejs_ibmcloud" {
  source             = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname           = "${var.hostname}"
  datacenter         = "${var.datacenter}"
  user_public_key_id = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key    = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key   = "${tls_private_key.ssh.private_key_pem}"
  module_script      = "files/installNodeJs.sh"
  os_reference_code  = "CENTOS_7_64"
  domain             = "cam.ibm.com"
  cores              = 1
  memory             = 1024
  disk1              = 25
}

#########################################################
# Output
#########################################################

output "The IP address of the VM with NodeJs installed" {
    value = "${module.install_nodejs_ibmcloud.public_ip}"
}
