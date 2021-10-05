##############################################################################
# Require terraform 0.9.3 or greater
##############################################################################
terraform {
  required_version = ">= 0.9.3"
}
##############################################################################
# IBM Cloud Provider
##############################################################################
# See the README for details on ways to supply these values
# Configure the IBM Cloud Provider
provider "ibm" {
  bluemix_api_key    = "${var.bluemix_api_key}"
  softlayer_username = "${var.softlayer_username}"
  softlayer_api_key  = "${var.softlayer_api_key}"
  version = "~> 0.5" 
}

variable bluemix_api_key {
  description = "Your IBM Cloud API Key."
}
variable softlayer_username {
  description = "Your IBM Cloud Infrastructure (SoftLayer) user name."
}
variable softlayer_api_key {
  description = "Your IBM Cloud Infrastructure (SoftLayer) API key."
}
