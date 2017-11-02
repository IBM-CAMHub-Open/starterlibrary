##################### Variables ###############################

variable "name" {
  description = "Name of the Virtual Machine"
}

variable "folder" {
  description = "Target vSphere folder for Virtual Machine"
  default     = ""
}

variable "datacenter" {
  description = "Target vSphere datacenter for Virtual Machine creation"
  default     = ""
}

variable "vcpu" {
  description = "Number of Virtual CPU for the Virtual Machine"
  default     = 1
}

variable "memory" {
  description = "Memory for Virtual Machine in MBs"
  default     = 1024
}

variable "cluster" {
  description = "Target vSphere Cluster to host the Virtual Machine"
  default     = ""
}

variable "network_label" {
  description = "vSphere Port Group or Network label for Virtual Machine's vNIC"
}

variable "ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "ipv4_prefix_length" {
  description = "IPv4 Prefix length for vNIC configuration"
}

variable "storage" {
  description = "Data store or storage cluster name for target VMs disks"
  default     = ""
}

variable "vm_template" {
  description = "Source VM or Template label for cloning"
}

variable "create_vm_folder" {
  description = "A vSphere folder need to be create or it is precreated"
  default     = false
}

variable "allow_selfsigned_cert" {
  description = "Communication with vsphere server with self signed certificate"
  default     = false
}

data "vsphere_datacenter" "datacenter" {
  name = "${var.datacenter}"
}

############### Optinal settings in provider ##########
provider "vsphere" {
  version = "~> 0.4"
  allow_unverified_ssl = "${var.allow_selfsigned_cert}"
}

################## Resources ###############################

#
# Create vSphere folder for the Virtual Machine
#
resource "vsphere_folder" "folder_vm_1" {
  count         = "${var.create_vm_folder}"
  path          = "${var.folder}"
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
  type          = "vm"
}

#
# Create VM with single vnic on a network label by cloning
#
resource "vsphere_virtual_machine" "vm_1" {
  depends_on = ["vsphere_folder.folder_vm_1"]
  name       = "${var.name}"
  folder     = "${var.folder}"
  datacenter = "${var.datacenter}"
  vcpu       = "${var.vcpu}"
  memory     = "${var.memory}"
  cluster    = "${var.cluster}"

  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.vm_template}"
  }
}
