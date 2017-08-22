#################################################################
# Terraform template that will deploy an VM with MariaDB only
#
# Version: 1.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017.
#
#################################################################

###########################################################
# Define the vsphere provider
#########################################################
provider "vsphere" {
  allow_unverified_ssl = true
}

#########################################################
# Define the variables
#########################################################
variable "name" {
  description = "Name of the Virtual Machine"
  default     = "mariadb-vm"
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
  description = "Memory for Virtual Machine in GBs"
  default     = 1
}

variable "cluster" {
  description = "Target vSphere Cluster to host the Virtual Machine"
  default     = "" 
}

variable "dns_suffixes" {
  description = "Name resolution suffixes for the virtual network adapter"
  type        = "list"
  default     = []
}

variable "dns_servers" {
  description = "DNS servers for the virtual network adapter"
  type        = "list"
  default     = []
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

variable "ssh_user" {
  description = "The user for ssh connection, which is default in template"
  default     = "root"
}

variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
}

#variable "camc_private_ssh_key" {
#  description = "The base64 encoded private key for ssh connection"
#}

variable "user_public_key" {
  description = "User-provided public SSH key used to connect to the virtual machine"
  default     = "None"
}

##############################################################
# Create Virtual Machine and install MariaDB
##############################################################
resource "vsphere_virtual_machine" "mariadb_vm" {
  name         = "${var.name}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.vcpu}"
  memory       = "${var.memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.ssh_user}"
    password    = "${var.ssh_user_password}"    
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${self.network_interface.0.ipv4_address}"
  }

  provisioner "file" {
    content = <<EOF
#!/bin/bash

LOGFILE="/var/log/addkey.log"

user_public_key=$1

mkdir -p .ssh
if [ ! -f .ssh/authorized_keys ] ; then
    touch .ssh/authorized_keys                                    >> $LOGFILE 2>&1 || { echo "---Failed to create authorized_keys---" | tee -a $LOGFILE; exit 1; }
    chmod 400 .ssh/authorized_keys                                >> $LOGFILE 2>&1 || { echo "---Failed to change permission of authorized_keys---" | tee -a $LOGFILE; exit 1; }
fi

if [ "$user_public_key" != "None" ] ; then
    echo "---start adding user_public_key----" | tee -a $LOGFILE 2>&1

    chmod 600 .ssh/authorized_keys                                >> $LOGFILE 2>&1 || { echo "---Failed to change permission of authorized_keys---" | tee -a $LOGFILE; exit 1; }
    echo "$user_public_key" | tee -a $HOME/.ssh/authorized_keys   >> $LOGFILE 2>&1 || { echo "---Failed to add user_public_key---" | tee -a $LOGFILE; exit 1; }
    chmod 400 .ssh/authorized_keys                                >> $LOGFILE 2>&1 || { echo "---Failed to change permission of authorized_keys---" | tee -a $LOGFILE; exit 1; }

    echo "---finish adding user_public_key----" | tee -a $LOGFILE 2>&1
fi

EOF
    destination = "/tmp/addkey.sh"
  }

  provisioner "file" {
    content = <<EOF
#!/bin/bash

LOGFILE="/var/log/install_mariadb.log"

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

echo "---start installing mariaDB---" | tee -a $LOGFILE 2>&1

retryInstall "yum install -y mariadb mariadb-server" >> $LOGFILE 2>&1 || { echo "---Failed to install MariaDB---" | tee -a $LOGFILE; exit 1; }
systemctl start mariadb                              >> $LOGFILE 2>&1 || { echo "---Failed to start MariaDB---" | tee -a $LOGFILE; exit 1; }
systemctl enable mariadb                             >> $LOGFILE 2>&1 || { echo "---Failed to enable MariaDB---" | tee -a $LOGFILE; exit 1; }

echo "---finish installing mariaDB---" | tee -a $LOGFILE 2>&1

EOF
    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\"",
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh"
    ]
  }
}

#########################################################
# Output
#########################################################
output "The IP address of the VM with MariaDB installed" {
    value = "${vsphere_virtual_machine.mariadb_vm.network_interface.0.ipv4_address}"
}
