################################################
# This module creates a free 1-node kubernetes cluster
# that will be the home of the web shop.
################################################

################################################
# Load org data
################################################
data "ibm_org" "orgData" {
  org                         = "${var.org}"
}

################################################
# Load space data
################################################
data "ibm_space" "spaceData" {
  space                       = "${var.space}"
  org                         = "${data.ibm_org.orgData.org}"
}

################################################
# Load account data
################################################
data "ibm_account" "accountData" {
  org_guid                    = "${data.ibm_org.orgData.id}"
}

################################################
# Create cloudant instance
################################################
resource "ibm_service_instance" "service" {
  name                        = "${var.servicename}-${random_pet.service.id}"
  space_guid                  = "${data.ibm_space.spaceData.id}"
  service                     = "${var.servicename}"
  plan                        = "${var.plan}"
}

################################################
# Generate access info
################################################
resource "ibm_service_key" "serviceKey" {
  name                        = "${var.servicename}-${random_pet.service.id}"
  service_instance_guid       = "${ibm_service_instance.service.id}"
}

################################################
# Generate a name
################################################
resource "random_pet" "service" {
  length                      = "2"
}
