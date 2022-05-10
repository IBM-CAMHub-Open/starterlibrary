
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    ibm = {
	source = "IBM-Cloud/ibm"
	version = ">= 1.38.2"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
