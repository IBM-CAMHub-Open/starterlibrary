#################################################################
# Terraform template that will deploy:
#    * MongoDB in one VM in SoftLayer
#    * NodeJS, AngularJS and Express in another VM in AWS
#    * Sample application
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
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

#########################################################
# Define the ibmcloud provider
#########################################################

provider "ibmcloud" {
}

#########################################################
# Define the variables
#########################################################
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

variable "network_name_prefix" {
  description = "The prefix of names for VPC, Gateway, Subnet and Security Group"
  default     = "opencontent-meanstack-hybrid"
}

variable "public_ssh_key_name" {
  description = "Name of the public SSH key used to connect to the virtual guests"
  default     = "cam-public-key-meanstack-hybrid"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guests"
}

variable "hostname-db" {
  description = "The hostname of server with mongo"
  default     = "meanstack-db"
}

variable "hostname-nodejs" {
  description = "The hostname of server with nodejs"
  default     = "meanstack-nodejs"
}

variable "softlayer_datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
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
module "build_network" {
  source                                = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/network/meanstack"
  network_name_prefix                   = "${var.network_name_prefix}"
  create_meanstack_mongo_security_group = false
}

##############################################################
# Create user-specified public key in AWS
##############################################################
resource "aws_key_pair" "cam_meanstack_public_key" {
  key_name   = "${var.public_ssh_key_name}"
  public_key = "${var.public_ssh_key}"
}

##############################################################
# Create user-specified public key in SoftLayer
##############################################################
resource "ibmcloud_infra_ssh_key" "cam_meanstack_public_key" {
    label      = "${var.public_ssh_key_name}"
    public_key = "${var.public_ssh_key}"
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

##############################################################
# Define the module to create a server and install mongo
##############################################################
module "install_meanstack_mongo_ibmcloud" {
  source                   = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//ibmcloud/virtual_guest"
  hostname                 = "${var.hostname-db}"
  datacenter               = "${var.softlayer_datacenter}"
  user_public_key_id       = "${ibmcloud_infra_ssh_key.cam_meanstack_public_key.id}"
  temp_public_key_id       = "${ibmcloud_infra_ssh_key.temp_public_key.id}"
  temp_public_key          = "${tls_private_key.ssh.public_key_openssh}"
  temp_private_key         = "${tls_private_key.ssh.private_key_pem}"
  module_script            = "files/installMongoDB.sh"
  module_script_variables  = "false"
  os_reference_code        = "CENTOS_7_64"
  domain                   = "cam.ibm.com"
  cores                    = 1
  memory                   = 1024
  disk1                    = 25
}

######################################################################################
# Define the module to create a server and install nodejs and sample application
######################################################################################
module "install_meanstack_nodejs_aws" {
  source                   = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//aws/ami_instance"
  aws_ami                  = "${module.find_ami.aws_ami}"
  aws_instance_type        = "t2.medium"
  aws_subnet_id            = "${module.build_network.subnet_id}"
  aws_security_group_id    = "${module.build_network.meanstack_nodejs_security_group_id}"
  aws_cam_public_key_id    = "${aws_key_pair.cam_meanstack_public_key.id}"
  hostname                 = "${var.hostname-nodejs}"
  module_script            = "files/installNodeJs.sh"
  module_script_name       = "installNodeJs.sh"
  module_script_variable_1 = "${module.install_meanstack_mongo_ibmcloud.public_ip}"
}

#########################################################
# Check status of application installation
#########################################################
module "check_meanstack_app_status" {
  source           = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git?ref=master//local/app_status"
  script_variables = "http://${module.install_meanstack_nodejs_aws.public_ip}:8443"
}

#########################################################
# Output
#########################################################
output "Meanstack DB Server IP Address" {
  value = "${module.install_meanstack_mongo_ibmcloud.public_ip}"
}

output "Meanstack NodeJS Server IP Address" {
  value = "${module.install_meanstack_nodejs_aws.public_ip}"
}

output "Please wait for 5 minutes and then can access the meanstack sample application" {
  value = "http://${module.install_meanstack_nodejs_aws.public_ip}:8443"
}
