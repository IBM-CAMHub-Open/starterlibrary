# This is a terraform generated template generated from final

##############################################################
# Keys - CAMC (public/private) & optional User Key (public)
##############################################################
variable "allow_unverified_ssl" {
  description = "Communication with vsphere server with self signed certificate"
  default     = "true"
}

##############################################################
# Define the vsphere provider
##############################################################
provider "vsphere" {
  allow_unverified_ssl = var.allow_unverified_ssl
  version              = "~> 1.3"
}

##############################################################
# Define pattern variables
##############################################################
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "nodejs_vm_datacenter" {
  name = var.nodejs_vm_datacenter
}

data "vsphere_datastore" "nodejs_vm_datastore" {
  name          = var.nodejs_vm_root_disk_datastore
  datacenter_id = data.vsphere_datacenter.nodejs_vm_datacenter.id
}

data "vsphere_resource_pool" "nodejs_vm_resource_pool" {
  name          = var.nodejs_vm_resource_pool
  datacenter_id = data.vsphere_datacenter.nodejs_vm_datacenter.id
}

data "vsphere_network" "nodejs_vm_network" {
  name          = var.nodejs_vm_network_interface_label
  datacenter_id = data.vsphere_datacenter.nodejs_vm_datacenter.id
}

data "vsphere_virtual_machine" "nodejs_vm_template" {
  name          = var.nodejs_vm_image
  datacenter_id = data.vsphere_datacenter.nodejs_vm_datacenter.id
}

##### Image Parameters variables #####

#Variable : nodejs_vm_name
variable "nodejs_vm_name" {
  type        = string
  description = "Generated"
  default     = "nodejs Vm"
}

#########################################################
##### Resource : nodejs_vm
#########################################################
variable "ssh_user" {
  description = "The user for ssh connection, which is default in template"
  default     = "root"
}

variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
}

variable "nodejs_vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "nodejs_vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "nodejs_vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "nodejs_vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default     = "1"
}

variable "nodejs_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "1024"
}

variable "nodejs_vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "nodejs_vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "nodejs_vm_dns_suffixes" {
  type        = list(string)
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "nodejs_vm_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
}

variable "nodejs_vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "nodejs_vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "nodejs_vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "nodejs_vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "nodejs_vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "nodejs_vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "nodejs_vm_root_disk_type" {
  type        = string
  description = "Type of template disk volume"
  default     = "eager_zeroed"
}

variable "nodejs_vm_root_disk_controller_type" {
  type        = string
  description = "Type of template disk controller"
  default     = "scsi"
}

variable "nodejs_vm_root_disk_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "nodejs_vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default     = "25"
}

variable "nodejs_vm_image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

module "provision_proxy_nodejs_vm" {
  source              = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git//vmware/proxy?ref=1.0"
  ip                  = var.nodejs_vm_ipv4_address
  id                  = vsphere_virtual_machine.nodejs_vm.id
  ssh_user            = var.ssh_user
  ssh_password        = var.ssh_user_password
  http_proxy_host     = var.http_proxy_host
  http_proxy_user     = var.http_proxy_user
  http_proxy_password = var.http_proxy_password
  http_proxy_port     = var.http_proxy_port
  enable              = length(var.http_proxy_host) > 0 ? "true" : "false"
}

# vsphere vm
resource "vsphere_virtual_machine" "nodejs_vm" {
  name             = var.nodejs_vm_name
  folder           = var.nodejs_vm_folder
  num_cpus         = var.nodejs_vm_number_of_vcpu
  memory           = var.nodejs_vm_memory
  resource_pool_id = data.vsphere_resource_pool.nodejs_vm_resource_pool.id
  datastore_id     = data.vsphere_datastore.nodejs_vm_datastore.id
  guest_id         = data.vsphere_virtual_machine.nodejs_vm_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.nodejs_vm_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.nodejs_vm_template.id

    customize {
      linux_options {
        domain    = var.nodejs_vm_domain
        host_name = var.nodejs_vm_name
      }

      network_interface {
        ipv4_address = var.nodejs_vm_ipv4_address
        ipv4_netmask = var.nodejs_vm_ipv4_prefix_length
      }

      ipv4_gateway    = var.nodejs_vm_ipv4_gateway
      dns_suffix_list = var.nodejs_vm_dns_suffixes
      dns_server_list = var.nodejs_vm_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.nodejs_vm_network.id
    adapter_type = var.nodejs_vm_adapter_type
  }

  disk {
    label          = "${var.nodejs_vm_name}0.vmdk"
    size           = var.nodejs_vm_root_disk_size
    keep_on_remove = var.nodejs_vm_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.nodejs_vm_datastore.id
  }
}

resource "null_resource" "nodejs_vm_install_nodejs" {
  depends_on = [
    vsphere_virtual_machine.nodejs_vm,
    module.provision_proxy_nodejs_vm,
  ]
  connection {
    type                = "ssh"
    user                = var.ssh_user
    password            = var.ssh_user_password
    host                = vsphere_virtual_machine.nodejs_vm.clone[0].customize[0].network_interface[0].ipv4_address
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  provisioner "file" {
    content = <<EOF
    #!/bin/bash
    set -o errexit
set -o nounset
set -o pipefail
LOGFILE="/var/log/install_nodejs.log"
retryInstall () {
  n=0
  max=5
  command=$1
  while [ $n -lt $max ]; do
    $command && break
    let n=n+1
    if [ $n -eq $max ]; then
      echo "---Exceed maximal number of retries---"
      exit 1
    fi
    sleep 15
   done
}
echo "---start installing node.js---" | tee -a $LOGFILE 2>&1
retryInstall "yum install gcc-c++ make -y"                >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_7.x | bash -    >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install nodejs -y"                      >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1

EOF


    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh",
    ]
  }
}

#########################################################
# Output
#########################################################
output "nodejs_server_ip_address" {
  value = vsphere_virtual_machine.nodejs_vm.clone[0].customize[0].network_interface[0].ipv4_address
}

