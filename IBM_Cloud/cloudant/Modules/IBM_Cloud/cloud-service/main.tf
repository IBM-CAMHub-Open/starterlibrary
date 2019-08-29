################################################
# This module creates a free 1-node kubernetes cluster
# that will be the home of the web shop.
################################################

################################################
# Load org data
################################################
# data "ibm_org" "orgData" {
#   org                         = "${var.org}"
# }

################################################
# Load space data
################################################
# data "ibm_space" "spaceData" {
#   space                       = "${var.space}"
#   org                         = "${data.ibm_org.orgData.org}"
# }

################################################
# Load account data
################################################
# data "ibm_account" "accountData" {
#   org_guid                    = "${data.ibm_org.orgData.id}"
# }

################################################
# Load resource group
################################################
data "ibm_resource_group" "group" {
  name = "${var.group}"
}

################################################
# Create cloudant instance
################################################
resource "ibm_resource_instance" "service" {
  name                        = "${var.servicename}-${random_pet.service.id}"
  service                     = "cloudantnosqldb"
  plan                        = "${var.plan}"
  location                    = "${var.region}"
  resource_group_id           = "${data.ibm_resource_group.group.id}"
  
}

################################################
# Generate access info
################################################
resource "ibm_resource_key" "resourceKey" {
  name                        = "${var.servicename}-${random_pet.service.id}"
  role                        = "Manager"
  resource_instance_id        = "${ibm_resource_instance.service.id}"
}

################################################
# Generate a name
################################################
resource "random_pet" "service" {
  length                      = "2"
}
