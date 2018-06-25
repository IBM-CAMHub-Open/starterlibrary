provider "ibm" {}

variable service_name {}
variable cf_org {}
variable cf_space {}

data "ibm_space" "spacedata" {
  space = "${var.cf_space}"
  org   = "${var.cf_org}"
}

resource "ibm_service_instance" "ibm-blockchain-net" {
  name       = "${var.service_name}"
  space_guid = "${data.ibm_space.spacedata.id}"
  service    = "ibm-blockchain-5-prod"
  plan       = "ibm-blockchain-plan-v1-ga1-starter-prod"
}

output service_name {
  value = "${ibm_service_instance.ibm-blockchain-net.name}"
}

output service_id {
  value = "${ibm_service_instance.ibm-blockchain-net.id}"
}

output url {
  value = "https://console.bluemix.net/services/ibm-blockchain-5-prod/${ibm_service_instance.ibm-blockchain-net.id}"
}
