
module "cloudant_service" {
  source  = "./Modules/IBM_Cloud/cloud-service"

  servicename = "cloudantNoSQLDB"
  org = "${var.org}"
  space = "${var.space}"
  plan = "${var.plan}"
  region = "${var.region}"
}
