#####
# AWS RDS Snapshot Template
#####

provider "aws" {
  version    = "~> 2.0"
  region     = var.aws_region
}

module "camtags" {
  source = "../Modules/camtags"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "db_instance_identifier" {
  type    = string
  default = ""
}

variable "db_snapshot_identifier" {
  type    = string
  default = ""
}

resource "aws_db_snapshot" "db_snapshot" {
  db_instance_identifier = var.db_instance_identifier
  db_snapshot_identifier = var.db_snapshot_identifier
  tags                   = module.camtags.tagsmap
}

output "aws_db_snapshot_id" {
  value = aws_db_snapshot.db_snapshot.id
}