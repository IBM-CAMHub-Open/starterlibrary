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
# ©Copyright IBM Corp. 2017, 2018.
#
##################################################################

#########################################################
# Define the AWS provider
#########################################################
provider "aws" {
  version = "~> 2.0"
  region  = "${var.aws_region}"
}

#########################################################
# Helper module for tagging
#########################################################
module "camtags" {
  source = "../Modules/camtags"
}


# Lookup for AMI based on image name and owner ID
data "aws_ami" "aws_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["${var.aws_image}*"]
  }
  owners = ["${var.aws_ami_owner_id}"]
}

#########################################################
# Build network
#########################################################
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-vpc"))}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-gateway"))}"
}

resource "aws_subnet" "primary" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}b"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-subnet"))}"
}

resource "aws_subnet" "secondary" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-subnet2"))}"
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.network_name_prefix}-db_subnet"
  subnet_ids = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-db_subnet"))}"
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-route-table"))}"
}

resource "aws_route_table_association" "primary" {
  subnet_id      = "${aws_subnet.primary.id}"
  route_table_id = "${aws_route_table.default.id}"
}

resource "aws_route_table_association" "secondary" {
  subnet_id      = "${aws_subnet.secondary.id}"
  route_table_id = "${aws_route_table.default.id}"
}

resource "aws_security_group" "application" {
  name        = "${var.network_name_prefix}-security-group-application"
  description = "Security group which applies to lamp application server"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-security-group-application"))}"
}

resource "aws_security_group" "database" {
  name        = "${var.network_name_prefix}-security-group-database"
  description = "Security group which applies to lamp mysql db"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-security-group-database"))}"
}

##############################################################
# Create user-specified public key in AWS
##############################################################
resource "aws_key_pair" "public_key" {
  key_name   = "${var.public_key_name}"
  public_key = "${var.public_key}"
}


##############################################################
# Create a server for php
##############################################################
resource "aws_instance" "web_server" {
  depends_on                  = ["aws_route_table_association.primary", "aws_route_table_association.secondary"]
  instance_type               = "t2.micro"
  ami                         = "${data.aws_ami.aws_ami.id}"
  subnet_id                   = "${aws_subnet.primary.id}"
  vpc_security_group_ids      = ["${aws_security_group.application.id}"]
  key_name                    = "${aws_key_pair.public_key.id}"
  associate_public_ip_address = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.php_instance_name}"))}"

}

resource "aws_instance" "db_server" {
  depends_on                  = ["aws_route_table_association.primary", "aws_route_table_association.secondary"]
  instance_type               = "t2.micro"
  ami                         = "${data.aws_ami.aws_ami.id}"
  subnet_id                   = "${aws_subnet.primary.id}"
  vpc_security_group_ids      = ["${aws_security_group.application.id}"]
  key_name                    = "${aws_key_pair.public_key.id}"
  associate_public_ip_address = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.db_instance_name}"))}"

}