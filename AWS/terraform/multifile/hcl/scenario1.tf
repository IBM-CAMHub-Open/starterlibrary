#################################################################
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

provider "aws" {
  version = "~> 2.0"
  region  = "${var.aws_region}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
}

module "public_ssh_key" {
  source         = "./ssh"
  key_name       = "Orpheus Public Key"
  public_ssh_key = "${var.public_ssh_key}"
}

resource "aws_instance" "orpheus_ubuntu_micro" {
  instance_type = "t2.micro"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"
  subnet_id     = "${aws_subnet.default.id}"

  #key_name      = "${aws_key_pair.orpheus_public_key.id}"
  key_name = "${module.public_ssh_key.key_pair_id}"
}
