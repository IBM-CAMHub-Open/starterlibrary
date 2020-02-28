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
data "vsphere_datacenter" "mongodb_vm_datacenter" {
  name = var.mongodb_vm_datacenter
}

data "vsphere_datastore" "mongodb_vm_datastore" {
  name          = var.mongodb_vm_root_disk_datastore
  datacenter_id = data.vsphere_datacenter.mongodb_vm_datacenter.id
}

data "vsphere_resource_pool" "mongodb_vm_resource_pool" {
  name          = var.mongodb_vm_resource_pool
  datacenter_id = data.vsphere_datacenter.mongodb_vm_datacenter.id
}

data "vsphere_network" "mongodb_vm_network" {
  name          = var.mongodb_vm_network_interface_label
  datacenter_id = data.vsphere_datacenter.mongodb_vm_datacenter.id
}

data "vsphere_virtual_machine" "mongodb_vm_template" {
  name          = var.mongodb_vm_image
  datacenter_id = data.vsphere_datacenter.mongodb_vm_datacenter.id
}

##### Image Parameters variables #####

#Variable : mongodb_vm_name
variable "mongodb_vm_name" {
  type        = string
  description = "Generated"
  default     = "mongodb Vm"
}

#########################################################
##### Resource : mongodb_vm
#########################################################
variable "ssh_user" {
  description = "The user for ssh connection, which is default in template"
  default     = "root"
}

variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
}

variable "mongodb_vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "mongodb_vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "mongodb_vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "mongodb_vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default     = "1"
}

variable "mongodb_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "1024"
}

variable "mongodb_vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "mongodb_vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "mongodb_vm_dns_suffixes" {
  type        = list(string)
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "mongodb_vm_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
}

variable "mongodb_vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "mongodb_vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "mongodb_vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "mongodb_vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "mongodb_vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "mongodb_vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "mongodb_vm_root_disk_type" {
  type        = string
  description = "Type of template disk volume"
  default     = "eager_zeroed"
}

variable "mongodb_vm_root_disk_controller_type" {
  type        = string
  description = "Type of template disk controller"
  default     = "scsi"
}

variable "mongodb_vm_root_disk_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "mongodb_vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default     = "25"
}

variable "mongodb_vm_image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

module "provision_proxy_mongodb_vm" {
  source              = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git//vmware/proxy?ref=1.0"
  ip                  = var.mongodb_vm_ipv4_address
  id                  = vsphere_virtual_machine.mongodb_vm.id
  ssh_user            = var.ssh_user
  ssh_password        = var.ssh_user_password
  http_proxy_host     = var.http_proxy_host
  http_proxy_user     = var.http_proxy_user
  http_proxy_password = var.http_proxy_password
  http_proxy_port     = var.http_proxy_port
  enable              = length(var.http_proxy_host) > 0 ? "true" : "false"
}

# vsphere vm
resource "vsphere_virtual_machine" "mongodb_vm" {
  name             = var.mongodb_vm_name
  folder           = var.mongodb_vm_folder
  num_cpus         = var.mongodb_vm_number_of_vcpu
  memory           = var.mongodb_vm_memory
  resource_pool_id = data.vsphere_resource_pool.mongodb_vm_resource_pool.id
  datastore_id     = data.vsphere_datastore.mongodb_vm_datastore.id
  guest_id         = data.vsphere_virtual_machine.mongodb_vm_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.mongodb_vm_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.mongodb_vm_template.id

    customize {
      linux_options {
        domain    = var.mongodb_vm_domain
        host_name = var.mongodb_vm_name
      }

      network_interface {
        ipv4_address = var.mongodb_vm_ipv4_address
        ipv4_netmask = var.mongodb_vm_ipv4_prefix_length
      }

      ipv4_gateway    = var.mongodb_vm_ipv4_gateway
      dns_suffix_list = var.mongodb_vm_dns_suffixes
      dns_server_list = var.mongodb_vm_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.mongodb_vm_network.id
    adapter_type = var.mongodb_vm_adapter_type
  }

  disk {
    label          = "${var.mongodb_vm_name}0.vmdk"
    size           = var.mongodb_vm_root_disk_size
    keep_on_remove = var.mongodb_vm_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.mongodb_vm_datastore.id
  }
}

resource "null_resource" "mongodb_vm_install_mongodb" {
  depends_on = [
    vsphere_virtual_machine.mongodb_vm,
    module.provision_proxy_mongodb_vm,
  ]
  connection {
    type                = "ssh"
    user                = var.ssh_user
    password            = var.ssh_user_password
    host                = vsphere_virtual_machine.mongodb_vm.clone[0].customize[0].network_interface[0].ipv4_address
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
LOGFILE="/var/log/install_mongodb.log"
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
#install mongodb
echo "---start installing mongodb---" | tee -a $LOGFILE 2>&1
mongo_repo=/etc/yum.repos.d/mongodb-org-3.4.repo
cat <<EOT | tee -a $mongo_repo                                                    >> $LOGFILE 2>&1 || { echo "---Failed to create mongo repo---" | tee -a $LOGFILE; exit 1; }
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOT
retryInstall "yum install -y mongodb-org"                                         >> $LOGFILE 2>&1 || { echo "---Failed to install mongodb-org---" | tee -a $LOGFILE; exit 1; }
sed -i -e 's/  bindIp/#  bindIp/g' /etc/mongod.conf                               >> $LOGFILE 2>&1 || { echo "---Failed to configure mongod---" | tee -a $LOGFILE; exit 1; }
service mongod start                                                              >> $LOGFILE 2>&1 || { echo "---Failed to start mongodb---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing mongodb---" | tee -a $LOGFILE 2>&1
if hash iptables 2>/dev/null; then
	#update firewall
	iptables -I INPUT 1 -p tcp -m tcp --dport 27017 -m conntrack --ctstate NEW -j ACCEPT     >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }
fi

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
output "db_server_ip_address" {
  value = vsphere_virtual_machine.mongodb_vm.clone[0].customize[0].network_interface[0].ipv4_address
}

