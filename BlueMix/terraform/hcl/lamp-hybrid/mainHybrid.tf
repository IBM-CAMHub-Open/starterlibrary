#################################################################
# Terraform template that will deploy:
#    * MySQL instance in AWS
#    * Apache and Php in SoftLayer
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
# Define the AWS provider
#########################################################
provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

#########################################################
# Define the ibmcloud provider
#########################################################
provider "ibmcloud" {
}

#########################################################
# Define the variables
#########################################################
variable "softlayer_datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "aws_access_key" {
  description = "AWS access key to request access to AWS account"
}

variable "aws_secret_key" {
  description = "AWS secret key to request access to AWS account"
}

variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-1"
}

variable "php_instance_name" {
  description = "The hostname of server with php"
  default     = "lampPhp"
}

variable "db_instance_name" {
  description = "The hostname of server with mysql"
  default     = "lampDb"
}

variable "network_name_prefix" {
  description = "The prefix of names for VPC, Gateway, Subnet and Security Group"
  default     = "opencontent-lamp-hybrid"
}

variable "public_key_name" {
  description = "Name of the public SSH key used to connect to the servers"
  default     = "cam-public-key-lamp-hybrid"
}

variable "public_key" {
  description = "Public SSH key used to connect to the servers"
}

variable "cam_user" {
  description = "user to be added into db and sshed into servers"
  default     = "camuser"
}

variable "cam_pwd" {
  description = "user password for cam user (minimal length is 8)"
}

##############################################################
# Create user-specified public key in AWS
##############################################################
resource "aws_key_pair" "cam_lamp_public_key" {
  key_name   = "${var.public_key_name}"
  public_key = "${var.public_key}"
}

##############################################################
# Create user-specified public key in SoftLayer
##############################################################
resource "ibmcloud_infra_ssh_key" "cam_lamp_public_key" {
    label      = "${var.public_key_name}"
    public_key = "${var.public_key}"
}

##############################################################
# Create temp public key for ssh connection in SoftLayer
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibmcloud_infra_ssh_key" "temp_public_key" {
  label      = "Temp Public Key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

#########################################################
# Define the modules to find resources
#########################################################
module "find_ami" {
  source     = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/resources/ami"
  aws_region = "${var.aws_region}"
}

#########################################################
# Define the modules to build network
#########################################################
module "awsNetwork" {
  source              = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/network/lamp"
  network_name_prefix = "${var.network_name_prefix}"
  primary_availability_zone = "${var.aws_region}b"
  secondary_availability_zone = "${var.aws_region}c"
}

##############################################################
# Define the module to create MySQL instance
##############################################################
module "awsMySQLInstance" {
  source               = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/mysql_instance"
  db_instance_name     = "${var.db_instance_name}"
  db_user              = "${var.cam_user}"
  db_pwd               = "${var.cam_pwd}"
  db_security_group_id = "${module.awsNetwork.database_security_group_id}"
  db_subnet_group_name = "${module.awsNetwork.database_subnet_group_name}"
  db_storage_size      = "10"
  db_default_az        = "${var.aws_region}b"
}

##############################################################
# Define the module to create a server and install mongo
##############################################################
module "install_lamp_php_ibmcloud" {
  source                   = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                 = "${var.php_instance_name}"
  datacenter               = "${var.softlayer_datacenter}"
  user_public_key_id       = "${ibmcloud_infra_ssh_key.cam_lamp_public_key.id}"
  temp_public_key_id       = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key          = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key         = "${tls_private_key.ssh.private_key_pem}"
  module_script            = "files/installLamp/setupApache2.sh"
  module_script_variables  = "${module.awsMySQLInstance.mysql_address} ${var.cam_user} ${var.cam_pwd}"
  os_reference_code        = "UBUNTU_16_64"
  domain                   = "cam.ibm.com"
  cores                    = 1
  memory                   = 1024
  disk1                    = 25
}

#########################################################
# Output
#########################################################
output "IBM Cloud PHP address" {
  value = "http://${module.install_lamp_php_ibmcloud.public_ip}/test.php"
}

output "MySQL address" {
  value = "${module.awsMySQLInstance.mysql_address}"
}
