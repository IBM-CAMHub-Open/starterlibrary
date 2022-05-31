#########################################################
# Define the variables
#########################################################
variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-1"
}

#Variable : AWS image name
variable "aws_image" {
  type        = string
  description = "Operating system image id / template that should be used when creating the virtual image"
  default     = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "aws_ami_owner_id" {
  description = "AWS AMI Owner ID"
  default     = "099720109477"
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

variable "private_key" {
  description = "Private SSH key used to connect to the servers"
}

