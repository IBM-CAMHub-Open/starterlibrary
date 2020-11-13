####
#Template AWS S3
###

provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

module "camtags" {
  source = "../Modules/camtags"
}

variable "name" {
  type    = string
  default = "s3-bucket-name"
}

variable "acl" {
  type    = string
  default = "private"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.name
  acl    = var.acl
  tags   = module.camtags.tagsmap
}

output "bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "bucket_tags" {
  value = aws_s3_bucket.bucket.tags
}