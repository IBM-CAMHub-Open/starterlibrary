#####
# IBM Databases - Template
#####

provider "ibm" {
  region     = var.db_location
  generation = 2
  version = ">= 1.0.0"
}

module "camtags" {
  source = "../Modules/camtags"
}

variable "resource_group" {
  type = string
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

variable "db_service" {
  default = "databases-for-postgresql"
}

variable "db_version" {
  default = ""
}

variable "db_location" {
  default = "us-south"
}

variable "db_plan" {
  default = "standard"
}

variable "db_instance_name" {
  type = string
}

variable "db_admin_password" {
  type = string
}

variable "members_memory_allocation_mb" {
  default = ""
}

variable "members_disk_allocation_mb" {
  default = ""
}

resource "ibm_database" "db_instance" {
  service                      = var.db_service
  version                      = var.db_version
  name                         = var.db_instance_name
  plan                         = var.db_plan
  location                     = var.db_location
  resource_group_id            = data.ibm_resource_group.group.id
  members_memory_allocation_mb = var.members_memory_allocation_mb != "" ? tonumber(var.members_memory_allocation_mb) : null
  members_disk_allocation_mb   = var.members_disk_allocation_mb != "" ? tonumber(var.members_disk_allocation_mb) : null
  adminpassword                = var.db_admin_password
  tags                         = module.camtags.tagslist
}

output "db_version" {
  value = ibm_database.db_instance.version
}

output "db_hosts" {
  value = ibm_database.db_instance.connectionstrings.0.hosts
}

output "db_admin_user" {
  value = ibm_database.db_instance.adminuser
}

output "db_database_name" {
  value = ibm_database.db_instance.connectionstrings.0.database
}

output "db_database_path" {
  value = ibm_database.db_instance.connectionstrings.0.path
}

output "db_connection_composed" {
  value = ibm_database.db_instance.connectionstrings.0.composed
}

output "db_certname" {
  value = ibm_database.db_instance.connectionstrings.0.certname
}

output "db_certbase64" {
  value = ibm_database.db_instance.connectionstrings.0.certbase64
}
