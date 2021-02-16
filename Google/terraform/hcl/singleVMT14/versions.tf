terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}