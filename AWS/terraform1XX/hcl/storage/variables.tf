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