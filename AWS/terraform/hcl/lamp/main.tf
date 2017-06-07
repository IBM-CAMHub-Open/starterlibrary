#################################################################
# Terraform template that will deploy two VMs in AWS with LAMP
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
}

#########################################################
# Define the variables
#########################################################
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
  default     = "opencontent-lamp"
}

variable "public_key_name" {
  description = "Name of the public SSH key used to connect to the servers"
  default     = "cam-public-key-lamp"
}

variable "public_key" {
  description = "Public SSH key used to connect to the servers"
}

variable "cam_user" {
  description = "User to be added into db and sshed into servers"
  default     = "camuser"
}

variable "cam_pwd" {
  description = "Password for cam user (minimal length is 8)"
}

##############################################################
# Create user-specified public key in AWS
##############################################################
resource "aws_key_pair" "cam_lamp_public_key" {
  key_name   = "${var.public_key_name}"
  public_key = "${var.public_key}"
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
  source                      = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/network/lamp"
  network_name_prefix         = "${var.network_name_prefix}"
  primary_availability_zone   = "${var.aws_region}b"
  secondary_availability_zone = "${var.aws_region}c"
}

##############################################################
# Define the module to create a server for php
##############################################################
module "awsPHPInstance" {
  source                   = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/ami_instance"
  aws_ami                  = "${module.find_ami.aws_ami}"
  aws_instance_type        = "t2.micro"
  aws_subnet_id            = "${module.awsNetwork.subnet_id}"
  aws_security_group_id    = "${module.awsNetwork.application_security_group_id}"
  aws_cam_public_key_id    = "${aws_key_pair.cam_lamp_public_key.id}"
  hostname                 = "${var.php_instance_name}"
  module_script            = "files/createCAMUser.sh"
  module_script_name       = "createCAMUser.sh"
  module_script_variable_1 = "${var.cam_user}"
  module_script_variable_2 = "${var.cam_pwd}"
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
# Define the module to install php
##############################################################
module "installPHP7aws" {
  source           = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/null_resource/installPHP"
  cam_user         = "${var.cam_user}"
  cam_pwd          = "${var.cam_pwd}"
  public_dns       = "${module.awsPHPInstance.public_dns}"
  public_mysql_dns = "${module.awsMySQLInstance.mysql_address}"
}

#########################################################
# Output
#########################################################
output "AWS PHP address" {
  value = "http://${module.awsPHPInstance.public_dns}/test.php"
}

output "MySQL address" {
  value = "${module.awsMySQLInstance.mysql_address}"
}
