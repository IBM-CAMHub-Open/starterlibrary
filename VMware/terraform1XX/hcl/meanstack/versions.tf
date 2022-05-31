
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.0.0"
    }
  }
}
