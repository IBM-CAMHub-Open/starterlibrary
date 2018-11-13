#####################################################################
##
##      Created 11/13/18 by admin. for Gtest_macys1
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

provider "aws" {
  access_key = "${var.aws_access_id}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
  version = "~> 1.8"
}


resource "aws_instance" "Gaws_macys_instance" {
  ami = "${var.Gaws_macys_instance_ami}"
  key_name = "${aws_key_pair.auth.id}"
  instance_type = "${var.Gaws_macys_instance_aws_instance_type}"
  availability_zone = "${var.availability_zone}"
  subnet_id  = "${aws_subnet.Gmacys_sub.id}"
  tags {
    Name = "${var.Gaws_macys_instance_name}"
  }
}

resource "tls_private_key" "ssh" {
    algorithm = "RSA"
}

resource "aws_key_pair" "auth" {
    key_name = "${var.aws_key_pair_name}"
    public_key = "${tls_private_key.ssh.public_key_openssh}"
}

resource "aws_vpc" "Gmacys_1" {
  cidr_block           = "0.0.0.0/0"
  enable_dns_hostnames = true

  tags {
    Name = "${var.network_name_prefix}"
  }
}

resource "aws_subnet" "Gmacys_sub" {
  vpc_id = "${aws_vpc.Gmacys_1.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "Main"
  }
}