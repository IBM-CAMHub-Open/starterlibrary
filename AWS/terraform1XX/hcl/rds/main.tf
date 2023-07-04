#####
# AWS RDS Template
#####
provider "aws" {
  region     = var.aws_region
}

module "camtags" {
  source = "../Modules/camtags"
}


variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "instance_name" {
  type    = string
  default = "mysql-camdb"
}

variable "license_model" {
  type    = string
  default = ""
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "engine_version" {
  type    = string
}

variable "instance_class" {
  type    = string
  default = "db.t2.micro"
}

variable "allocated_storage" {
  type    = string
  default = "10"
}

variable "username" {
  type    = string
  default = "mysqlusr"
}

variable "password" {
  type    = string
  default = "my1sqlusr"
}

variable "subnet_group_name" {
  type    = string
}

variable "vpc_security_group_ids" {
  type    = list(string)
}

variable "snapshot_identifier" {
  type    = string
}

variable "publicly_accessible" {
  type    = bool
}

variable "skip_final_snapshot" {
  type    = bool
}

variable "final_snapshot_identifier" {
  type    = string
 }


resource "aws_db_instance" "db_instance" {
  db_name                   	= var.instance_name
  identifier_prefix      	= var.instance_name != "" ? lower(var.instance_name) : null
  allocated_storage      	= var.allocated_storage != "" ? tonumber(var.allocated_storage) : null
  engine                 	= var.db_engine
  engine_version         	= var.engine_version
  instance_class         	= var.instance_class
  username               	= var.username
  password               	= var.password
  publicly_accessible    	= var.publicly_accessible
  db_subnet_group_name   	= var.subnet_group_name
  vpc_security_group_ids 	= var.vpc_security_group_ids
  skip_final_snapshot    	= var.skip_final_snapshot
  snapshot_identifier    	= var.snapshot_identifier
  final_snapshot_identifier	= var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : null
  license_model             = var.license_model
  tags                      = module.camtags.tagsmap
}


output "aws_db_instance_identifier" {
  value = aws_db_instance.db_instance.identifier
}

output "aws_db_instance_engine" {
  value = aws_db_instance.db_instance.engine
}

output "aws_db_instance_engine_version" {
  value = aws_db_instance.db_instance.engine_version
}

output "aws_db_instance_endpoint" {
  value = aws_db_instance.db_instance.endpoint
}

output "aws_db_instance_status" {
  value = aws_db_instance.db_instance.status
}
