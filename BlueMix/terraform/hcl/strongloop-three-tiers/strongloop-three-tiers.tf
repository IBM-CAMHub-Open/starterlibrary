#################################################################
# Terraform template that will deploy three VMs with:
#    * StrongLoop in Strongloop-VM
#    * NodeJS in Strongloop-VM and Angular-VM
#    * AngularJS in Angular-VM
#    * MongoDB in MongoDB-VM
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

variable "strongloop-server-hostname" {
  description = "Hostname of the virtual instance (with Strongloop and NodeJS installed) to be deployed"
  default     = "strongloop-vm"
}

variable "angular-server-hostname" {
  description = "Hostname of the virtual instance (with AngularJS and NodeJS installed) to be deployed"
  default     = "angularjs-vm"
}

variable "mongodb-server-hostname" {
  description = "Hostname of the virtual instance (with MongoDB installed) to be deployed"
  default     = "mongodb-vm"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guests"
}

variable "mongodb_user_password" {
  description = "The password of an user in mongodb for sample application"
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
# Define the module to create a server and install mongoDB
##############################################################################
module "install_mongodb_ibmcloud" {
  source                   = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                 = "${var.mongodb-server-hostname}"
  datacenter               = "${var.datacenter}"
  user_public_key_id       = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id       = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key          = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key         = "${tls_private_key.ssh.private_key_pem}"
  module_script            = "files/installMongoDB.sh"
  module_script_variables  = "true ${var.mongodb_user_password}"
  os_reference_code        = "CENTOS_7_64"
  domain                   = "cam.ibm.com"
  cores                    = 2
  memory                   = 4096
  disk1                    = 25
}

##############################################################################
# Define the module to create a server and install strongloop
##############################################################################
module "install_strongloop_ibmcloud" {
  source                        = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                      = "${var.strongloop-server-hostname}"
  datacenter                    = "${var.datacenter}"
  user_public_key_id            = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id            = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key               = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key              = "${tls_private_key.ssh.private_key_pem}"
  module_script                 = "files/installStrongloopThreeTiers/installStrongloop.sh"
  module_sample_application_url = "not_required"
  module_script_variables       = "${module.install_mongodb_ibmcloud.public_ip} ${var.mongodb_user_password} true"
  os_reference_code             = "CENTOS_7_64"
  domain                        = "cam.ibm.com"
  cores                         = 2
  memory                        = 4096
  disk1                         = 25
}

##############################################################################
# Define the module to create a server and install angular
##############################################################################
module "install_angular_ibmcloud" {
  source                        = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                      = "${var.angular-server-hostname}"
  datacenter                    = "${var.datacenter}"
  user_public_key_id            = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id            = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key               = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key              = "${tls_private_key.ssh.private_key_pem}"
  module_script                 = "files/installStrongloopThreeTiers/installAngularJs.sh"
  module_sample_application_url = "not_required"
  module_script_variables       = "${module.install_strongloop_ibmcloud.public_ip} 8080 true"
  os_reference_code             = "CENTOS_7_64"
  domain                        = "cam.ibm.com"
  cores                         = 2
  memory                        = 4096
  disk1                         = 25
}

#########################################################
# Output
#########################################################
output "The mongodb server's ip addresses" {
    value = "${module.install_mongodb_ibmcloud.public_ip}"
}

output "The strongloop server's ip addresses" {
    value = "${module.install_strongloop_ibmcloud.public_ip}"
}

output "The angular server's ip addresses" {
    value = "${module.install_angular_ibmcloud.public_ip}"
}

output "Please access the strongloop-three-tiers sample application using the following url" {
    value = "http://${module.install_angular_ibmcloud.public_ip}:8080"
}
