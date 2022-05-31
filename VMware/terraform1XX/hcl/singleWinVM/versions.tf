
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.1.1"
    }
  }
}
