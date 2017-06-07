#################################################################
# Terraform template that will deploy one Pod in Kubernetes
#    * Nginx Pod
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

variable "clustername" {
    description = "Cluster name"
}
variable "count" {
    description = "Number of managed nodes"
}
variable "datacenter" {
    description = "Softlayer datacenter where infrastructure resources will be deployed"
}
variable "public_ssh_key" {
    description = "public ssh key to add to each kubernetes host virtual machine"
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
# Define the module to create a Kubernetes Master server
##############################################################################
module "install_kubernetes_master_ibmcloud" {
  source                  = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                = "${var.clustername}"
  datacenter              = "${var.datacenter}"
  user_public_key_id      = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id      = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key         = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key        = "${tls_private_key.ssh.private_key_pem}"
  module_script           = "files/installKubernetes/installKubernetesMaster.sh"
  remove_temp_private_key = "false"
  os_reference_code       = "CENTOS_7_64"
  domain                  = "cam.ibm.com"
  cores                   = 2
  memory                  = 4096
  disk1                   = 25
}

##############################################################################
# Define the module to create Kubernetes minion servers
##############################################################################
module "install_kubernetes_node_ibmcloud" {
  count                   = "${var.count}"
  source                  = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/cluster"
  hostname                = "${var.clustername}"
  datacenter              = "${var.datacenter}"
  user_public_key_id      = "${ibmcloud_infra_ssh_key.cam_public_key.id}"
  temp_public_key_id      = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key         = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key        = "${tls_private_key.ssh.private_key_pem}"
  module_script           = "files/installKubernetesNode.sh"
  module_script_variables = "${module.install_kubernetes_master_ibmcloud.public_ip}"
  os_reference_code       = "CENTOS_7_64"
  domain                  = "cam.ibm.com"
  cores                   = 2
  memory                  = 4096
  disk1                   = 25
}

##############################################################################
# Define the module to install Nginx
##############################################################################
module "install_kubernetes_nginx" {
  source                  = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/null_resource"
  remote_host             = "${module.install_kubernetes_master_ibmcloud.public_ip}"
  module_script           = "files/installKubernetesNginx.sh"
  module_script_variables = "${var.count}"
  module_custom_commands  = "echo ${module.install_kubernetes_node_ibmcloud.public_ip}; reboot"
  temp_public_key         = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key        = "${tls_private_key.ssh.private_key_pem}"
}

#########################################################
# Output
#########################################################

output "Please access the kubernetes dashboard" {
    value = "http://${module.install_kubernetes_master_ibmcloud.public_ip}:8080/ui"
}
output "Please be aware that node's ip addresses" {
    value = ["${split(",", module.install_kubernetes_node_ibmcloud.public_ip)}"]
}
