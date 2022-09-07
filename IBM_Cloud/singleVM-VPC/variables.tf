variable "region" {
  type    = string
  default = "us-east"
}

variable "public_ssh_key" {
  type = string
}

variable "image_name" {
  type    = string
  default = "ibm-debian-10-0-64-minimal-for-vsi"
}

variable "profile" {
  type    = string
  default = "bx2-2x8"
}

variable "zone" {
  type    = string
  default = "us-east-1"
}

variable "resource_prefix" {
  type    = string
  default = "cam"
}
