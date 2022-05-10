
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = ">= 1.47.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.1.2"
    }
  }
}
