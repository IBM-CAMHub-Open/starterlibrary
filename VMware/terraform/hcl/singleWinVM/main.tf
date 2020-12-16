# Configure the VMware vSphere Provider
provider "vsphere" {
  # user = "${var.vsphere_user}"
  # password = "${var.vsphere_password}"
  # vsphere_server = "${var.vsphere_server}"
  version              = "~> 1.3"
  allow_unverified_ssl = "true"
}

/*variable "vsphere_server"{
  description = "vCenter IP"
}

variable "vsphere_user"{
  description = "vCenter user ID"
}

variable "vsphere_password"{
  description = "vCenter login password"
}*/

##############################################################
# Vsphere data for provider 
##############################################################
data "vsphere_datacenter" "vsphere_datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "vsphere_datastore" {
  name          = var.vm_disk1_datastore
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter.id
}

data "vsphere_resource_pool" "vsphere_resource_pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter.id
}

data "vsphere_network" "vm_network" {
  name          = var.vm_network_interface_label
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter.id
}

data "vsphere_virtual_machine" "vm_template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter.id
}

#########################################################
##### Resource : vm_Inout variable
#########################################################

variable "enable_vm" {
  type    = string
  default = "true"
}

variable "vm_name" {
  type = list(string)
}

#
variable "hostName" {
  description = "VM hostanme"
  type        = list(string)
}

variable "vm_vcpu" {
  description = "VM Vcpu count"
  default     = "2"
}

variable "vm_memory" {
  description = "VM memory"
}

variable "admin_password" {
  description = "Windows admin password"
}

variable "vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "vm_template" {
  description = "Target vSphere folder for virtual machine"
}

variable "vsphere_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "vsphere_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "vm_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
}

variable "vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
  default     = "VM Network"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "vm_ipv4_address" {
  default     = []
  description = "IPv4 address for vNIC configuration"
  type        = list(string)
}

variable "vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "vm_disk1_size" {
  description = "Size of template disk volume"
}

variable "vm_disk1_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "vm_disk1_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "dependsOn" {
  default     = "true"
  description = "Boolean for dependency"
}

######################
# Output Variable
output "address" {
  value = vsphere_virtual_machine.Win-vm.*.clone.0.customize.0.network_interface.0.ipv4_address
}

############ Resource block
resource "null_resource" "dependsOn" {
  provisioner "local-exec" {
    command = "echo '================= dependsOn ${var.dependsOn} ================'"
  }
}

resource "vsphere_virtual_machine" "Win-vm" {
  depends_on = [null_resource.dependsOn]

  count = var.enable_vm == "true" ? length(var.vm_ipv4_address) : 0

  name             = var.vm_name[count.index]
  folder           = var.vm_folder
  num_cpus         = var.vm_vcpu
  memory           = var.vm_memory
  resource_pool_id = data.vsphere_resource_pool.vsphere_resource_pool.id
  datastore_id     = data.vsphere_datastore.vsphere_datastore.id
  guest_id         = data.vsphere_virtual_machine.vm_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.vm_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id

    customize {
      windows_options {
        computer_name    = element(var.hostName, count.index)
        workgroup        = "workgroup"
        admin_password   = var.admin_password
        auto_logon       = true
        auto_logon_count = 1
      }
      network_interface {
        ipv4_address = var.vm_ipv4_address[count.index]
        ipv4_netmask = var.vm_ipv4_prefix_length
      }

      ipv4_gateway    = var.vm_ipv4_gateway
      dns_server_list = var.vm_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.vm_network.id
    adapter_type = var.vm_adapter_type
  }

  disk {
    label            = "${var.vm_name[count.index]}.vmdk"
    size             = var.vm_disk1_size
    keep_on_remove   = var.vm_disk1_keep_on_remove
    datastore_id     = data.vsphere_datastore.vsphere_datastore.id
    thin_provisioned = "true"
  }
}

resource "null_resource" "Win-vm-create_done" {
  depends_on = [vsphere_virtual_machine.Win-vm]
  count = var.enable_vm == "true" ? length(var.vm_ipv4_address) : 0
  provisioner "local-exec" {
    command = "echo '===================== Windows VM creates done for ${var.vm_name[count.index]} ==================X .'"
  }
}

