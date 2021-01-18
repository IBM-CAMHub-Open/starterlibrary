#
# Define a NSX tag which can be used later to easily to
# search for the created objects in NSX.
#
variable "nsxt_tag_scope" {
  type = "string"
}

variable "nsxt_tag" {
  type = "string"
}

#
# Define a NSX transport zone needed by switch
#
variable "nsxt_transport_zone" {
  type = "string"
}

variable "nsxt_logical_switch_name" {
  type = "string"
}

variable "nsxt_logical_switch_desc" {
  type = "string"
}

variable "nsxt_logical_switch_state" {
  default = "UP"
  type = "string"
}

variable "nsxt_logical_switch_repl_mode" {
  default = "MTEP"
  type = "string"
}

##############################################################
# Define the nsxt provider
##############################################################
provider "nsxt" {
  version = ">= 1.1.1, <= 3.1.0"
}

#
#Transport Zone DS
#
data "nsxt_transport_zone" "transport_zone1" {
  display_name = "${var.nsxt_transport_zone}"
}

#
# Create a NSX logical switch to which you
# can attach virtual machines.
#
resource "nsxt_logical_switch" "switch1" {
  admin_state       = "${var.nsxt_logical_switch_state}"
  description       = "${var.nsxt_logical_switch_desc}"
  display_name      = "${var.nsxt_logical_switch_name}"
  transport_zone_id = "${data.nsxt_transport_zone.transport_zone1.id}"
  replication_mode  = "${var.nsxt_logical_switch_repl_mode}"

  tag {
    scope = "${var.nsxt_tag_scope}"
    tag   = "${var.nsxt_tag}"
  }
}

