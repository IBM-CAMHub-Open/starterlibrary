# =================================================================
# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =================================================================

# This is a terraform generated template generated from LAMPStarter

##############################################################
# Keys - CAMC (public/private) & optional User Key (public)
##############################################################
variable "user_public_ssh_key" {
  type        = string
  description = "User defined public SSH key used to connect to the virtual machine. The format must be in openSSH."
  default     = "None"
}

variable "ibm_stack_id" {
  description = "A unique stack id."
}

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
##### unique stack name #####
variable "ibm_stack_name" {
  description = "A unique stack name."
}

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

##### mongodb_vm variables #####
#Variable : mongodb_vm_image
variable "mongodb_vm_image" {
  type        = string
  description = "Operating system image id / template that should be used when creating the virtual image"
}

#Variable : mongodb_vm_name
variable "mongodb_vm_name" {
  type        = string
  description = "Short hostname of virtual machine"
}

#Variable : mongodb_vm_os_admin_user
variable "mongodb_vm_os_admin_user" {
  type        = string
  description = "Name of the admin user account in the virtual machine that will be accessed via SSH"
}

##### nodejs_vm variables #####
#Variable : nodejs_vm_image
variable "nodejs_vm_image" {
  type        = string
  description = "Operating system image id / template that should be used when creating the virtual image"
}

#Variable : nodejs_vm_name
variable "nodejs_vm_name" {
  type        = string
  description = "Short hostname of virtual machine"
}

#Variable : nodejs_vm_os_admin_user
variable "nodejs_vm_os_admin_user" {
  type        = string
  description = "Name of the admin user account in the virtual machine that will be accessed via SSH"
}

##### virtualmachine variables #####

##### ungrouped variables #####

#########################################################
##### Resource : mongodb_vm
#########################################################

variable "mongodb_vm_os_password" {
  type        = string
  description = "Operating System Password for the Operating System User to access virtual machine"
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
  default     = "2"
}

variable "mongodb_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "2048"
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

  # Specify the connection
  # Specify the connection
  connection {
    host                = self.default_ip_address
    type                = "ssh"
    user                = var.mongodb_vm_os_admin_user
    password            = var.mongodb_vm_os_password
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  provisioner "file" {
    destination = "mongodb_vm_add_ssh_key.sh"

    content = <<EOF
# =================================================================
# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =================================================================
#!/bin/bash

if (( $# != 2 )); then
echo "usage: arg 1 is user, arg 2 is public key"
exit -1
fi

userid="$1"
ssh_key="$2"

user_home=$(eval echo "~$userid")
user_auth_key_file=$user_home/.ssh/authorized_keys
echo "$user_auth_key_file"
if ! [ -f $user_auth_key_file ]; then
echo "$user_auth_key_file does not exist on this system, creating."
mkdir $user_home/.ssh
chmod 700 $user_home/.ssh
touch $user_home/.ssh/authorized_keys
chmod 600 $user_home/.ssh/authorized_keys
else
echo "user_home : $user_home"
fi

if [[ $ssh_key = 'None' ]]; then
echo "skipping user key add, 'None' specified"
else
echo "$user_auth_key_file"
echo "$ssh_key" >> "$user_auth_key_file"
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file"
exit -1
else
echo "updated $user_auth_key_file"
fi
fi

EOF

  }

  # Execute the script remotely
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "bash -c 'chmod +x mongodb_vm_add_ssh_key.sh'",
      "bash -c './mongodb_vm_add_ssh_key.sh  \"${var.mongodb_vm_os_admin_user}\" \"${var.user_public_ssh_key}\">> mongodb_vm_add_ssh_key.log 2>&1'",
    ]
  }
}

#########################################################
##### Resource : mongodb_vm_install_mongodb
#########################################################

resource "null_resource" "mongodb_vm_install_mongodb" {
  depends_on = [vsphere_virtual_machine.mongodb_vm]

  # Specify the ssh connection
  # Specify the ssh connection
  connection {
    user                = var.mongodb_vm_os_admin_user
    password            = var.mongodb_vm_os_password
    host                = vsphere_virtual_machine.mongodb_vm.clone[0].customize[0].network_interface[0].ipv4_address
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  provisioner "file" {
    destination = "mariadb_vm_install_mariadb.properties"

    content = <<EOF

EOF

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
	iptables -I INPUT 1 -p tcp -m tcp --dport 27017 -m conntrack --ctstate NEW -j ACCEPT   >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }
fi
EOF


    destination = "/tmp/installation.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh",
    ]
  }
}

#########################################################
##### Resource : nodejs_vm
#########################################################

variable "nodejs_vm_os_password" {
  type        = string
  description = "Operating System Password for the Operating System User to access virtual machine"
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
  default     = "2"
}

variable "nodejs_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "2048"
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
    label          = "${var.nodejs_vm_name}.vmdk"
    size           = var.nodejs_vm_root_disk_size
    keep_on_remove = var.nodejs_vm_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.nodejs_vm_datastore.id
  }

  # Specify the connection
  # Specify the connection
  connection {
    host                = self.default_ip_address
    type                = "ssh"
    user                = var.nodejs_vm_os_admin_user
    password            = var.nodejs_vm_os_password
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  provisioner "file" {
    destination = "nodejs_vm_add_ssh_key.sh"

    content = <<EOF
# =================================================================
# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =================================================================
#!/bin/bash

if (( $# != 2 )); then
echo "usage: arg 1 is user and arg 2 is public key"
exit -1
fi

userid="$1"
ssh_key="$2"

user_home=$(eval echo "~$userid")
user_auth_key_file=$user_home/.ssh/authorized_keys
echo "$user_auth_key_file"
if ! [ -f $user_auth_key_file ]; then
echo "$user_auth_key_file does not exist on this system, creating."
mkdir $user_home/.ssh
chmod 700 $user_home/.ssh
touch $user_home/.ssh/authorized_keys
chmod 600 $user_home/.ssh/authorized_keys
else
echo "user_home : $user_home"
fi

if [[ $ssh_key = 'None' ]]; then
echo "skipping user key add, 'None' specified"
else
echo "$user_auth_key_file"
echo "$ssh_key" >> "$user_auth_key_file"
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file"
exit -1
else
echo "updated $user_auth_key_file"
fi
fi

EOF

  }

  # Execute the script remotely
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "bash -c 'chmod +x nodejs_vm_add_ssh_key.sh'",
      "bash -c './nodejs_vm_add_ssh_key.sh  \"${var.nodejs_vm_os_admin_user}\" \"${var.user_public_ssh_key}\">> nodejs_vm_add_ssh_key.log 2>&1'",
    ]
  }
}

#########################################################
##### Resource : nodejs_vm_install_nodejs
#########################################################

resource "null_resource" "nodejs_vm_install_nodejs" {
  depends_on = [vsphere_virtual_machine.nodejs_vm]

  # Specify the ssh connection
  # Specify the ssh connection
  connection {
    user                = var.nodejs_vm_os_admin_user
    password            = var.nodejs_vm_os_password
    host                = vsphere_virtual_machine.nodejs_vm.clone[0].customize[0].network_interface[0].ipv4_address
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  provisioner "file" {
    destination = "mariadb_vm_install_mariadb.properties"

    content = <<EOF

EOF

  }

  provisioner "file" {
    content = <<EOF
  #!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
LOGFILE="/var/log/install_nodejs.log"
DBADDRESS=$1
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
echo "---Install nodejs---" | tee -a $LOGFILE 2>&1
retryInstall "yum install gcc-c++ make -y"                                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_12.x | bash -                                                            >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install nodejs -y"                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
npm install -g bower gulp                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to install bower and gulp---" | tee -a $LOGFILE; exit 1; }
echo "---Install mean sample application---" | tee -a $LOGFILE 2>&1
retryInstall "yum install -y git"                                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to install git---" | tee -a $LOGFILE; exit 1; }
git clone https://github.com/meanjs/mean.git mean                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to clone mean sample project---" | tee -a $LOGFILE; exit 1; }
cd mean
yum groupinstall 'Development Tools' -y                                                                           >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install -y libpng-devel"                                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install libpng---" | tee -a $LOGFILE; exit 1; }
npm install --unsafe-perm=true                                                                                    >> $LOGFILE 2>&1 || { echo "---Failed to install node modules---" | tee -a $LOGFILE; exit 1; }
bower --allow-root --config.interactive=false install                                                             >> $LOGFILE 2>&1 || { echo "---Failed to install bower---" | tee -a $LOGFILE; exit 1; }
PRODCONF=config/env/production.js
sed -i -e "/    uri: process.env.MONGOHQ_URL/a\ \ \ \ uri: \'mongodb:\/\/"$DBADDRESS":27017/mean\'," $PRODCONF    >> $LOGFILE 2>&1 || { echo "---Failed to update db config---" | tee -a $LOGFILE; exit 1; }
sed -i -e 's/    uri: process.env.MONGOHQ_URL/\/\/    uri: process.env.MONGOHQ_URL/g' $PRODCONF                   >> $LOGFILE 2>&1 || { echo "---Failed to update db config---" | tee -a $LOGFILE; exit 1; }
sed -i -e 's/ssl: true/ssl: false/g' $PRODCONF                                                                    >> $LOGFILE 2>&1 || { echo "---Failed to update db config---" | tee -a $LOGFILE; exit 1; }
#make sample application as a service
SAMPLE_APP_SERVICE_CONF=/etc/systemd/system/nodeserver.service
cat << EOT > $SAMPLE_APP_SERVICE_CONF
[Unit]
Description=Node.js Example Server
[Service]
ExecStart=/usr/bin/gulp prod --gulpfile $HOME/mean/gulpfile.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodejs-example
Environment=NODE_ENV=production PORT=8443
[Install]
WantedBy=multi-user.target
EOT
systemctl enable nodeserver.service                                                                               >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
systemctl start nodeserver.service                                                                                >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }
if hash iptables 2>/dev/null; then
	#update firewall
	iptables -I INPUT 1 -p tcp -m tcp --dport 8443 -m conntrack --ctstate NEW -j ACCEPT                           >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }
fi
echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1
EOF


    destination = "/tmp/installation.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.mongodb_vm.clone[0].customize[0].network_interface[0].ipv4_address}\"",
    ]
  }
}

#########################################################
# Output
#########################################################
output "meanstack_db_server_ip_address" {
  value = vsphere_virtual_machine.mongodb_vm.clone[0].customize[0].network_interface[0].ipv4_address
}

output "meanstack_nodejs_server_ip_address" {
  value = vsphere_virtual_machine.nodejs_vm.clone[0].customize[0].network_interface[0].ipv4_address
}

output "meanstack_sample_application_url" {
  value = "http://${vsphere_virtual_machine.nodejs_vm.clone[0].customize[0].network_interface[0].ipv4_address}:8443"
}

