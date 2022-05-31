
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.0"
    }
    vsphere = {
      source   = "hashicorp/vsphere"
      version  = ">= 2.0"
    }
  }
}
