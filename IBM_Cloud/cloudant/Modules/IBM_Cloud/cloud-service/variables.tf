
variable "servicename" {
  type                        = "string"
  description                 = "Specify the service name you want to create"
}
variable "plan" {
  type                        = "string"
  description                 = "Specify the corresponding plan for the service you selected"
}

variable "group" {
  type                        = "string"
  description                 = "IBM Cloud resource group"
}

variable "region" {
  type                        = "string"
  description                 = "IBM Cloud region"
  default                     = "eu-gb"
}
