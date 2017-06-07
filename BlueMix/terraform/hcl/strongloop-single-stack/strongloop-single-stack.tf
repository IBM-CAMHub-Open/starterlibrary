#################################################################
# Terraform template that will deploy an VM with:
#    * MongoDB
#    * NodeJS
#    * AngularJS
#    * StrongLoop
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
    label      = "CAM Public Key"
    public_key = "${var.public_ssh_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibmcloud_infra_ssh_key" "temp_public_key" {
  label      = "Temp Public Key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################################
# Define the module to create a server and install strongloop-single-stack
##############################################################################
module "install_strongloop_single_stack_ibmcloud" {
  source                        = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                      = "${var.hostname}"
  datacenter                    = "${var.datacenter}"
  user_public_key_id            = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id            = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key               = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key              = "${tls_private_key.ssh.private_key_pem}"
  module_script                 = "files/installStrongloopSingleStack.sh"
  module_sample_application_url = "not_required"
  os_reference_code             = "CENTOS_7_64"
  domain                        = "cam.ibm.com"
  cores                         = 2
  memory                        = 4096
  disk1                         = 25

}

#########################################################
# Output
#########################################################

output "Please access the strongloop-single-stack sample application using the following url" {
    value = "http://${module.install_strongloop_single_stack_ibmcloud.public_ip}:3000"
}
