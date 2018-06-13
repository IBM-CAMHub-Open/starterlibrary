
variable "org" {
  type                        = "string"
  description                 = "Your Bluemix ORG"
}

variable "space" {
  type                        = "string"
  description                 = "Your Bluemix Space"
}

variable "servicename" {
/*
"options": [
  {
    "value": "cloudantNoSQLDB",
    "label": "Cloudant NoSQL DB is a fully managed data layer designed for modern web and mobile applications that leverages a flexible JSON schema. Cloudant is built upon and compatible with Apache CouchDB and accessible through a secure HTTPS API, which scales as your application grows. Cloudant is ISO27001 and SOC2 Type 1 certified, and all data is stored in triplicate across separate physical nodes in a cluster for HA/DR within a data center."
  }
]
*/
  type                        = "string"
  description                 = "Specify the service name you want to create"
  default                     = "cloudantNoSQLDB"
}

variable "plan" {
  type                        = "string"
  description                 = "Specify the corresponding plan for the service you selected"
}

variable "region" {
  type                        = "string"
  description                 = "Bluemix region"
  default                     = "eu-gb"
}
