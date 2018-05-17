variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_image_size" {
  description = "AWS Image Instance Size"
  default     = "t2.small"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

# Ubuntu 14.04.01 as documented at https://cloud-images.ubuntu.com/releases/14.04/14.04.1/
variable "aws_amis" {
  default = {
    us-west-1 = "ami-0db4b748"
    us-east-1 = "ami-b227efda"
  }
}
