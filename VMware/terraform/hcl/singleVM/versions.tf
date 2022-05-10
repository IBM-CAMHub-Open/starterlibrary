
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    camc = {
      source  = "registry.ibm.com/cam/camc"
      version = "0.2.5"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = ">= 2.1.1"
    }
  }
}
