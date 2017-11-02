#################################################################
# Terraform template that will deploy:
#    * MongoDB in one VM 
#    * NodeJS, AngularJS and Express in another VM
#    * Sample application
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

#########################################################
# Define the vsphere provider
#########################################################
provider "vsphere" {
  version = "~> 0.4"
  allow_unverified_ssl = true
}

#########################################################
# Define the variables
#########################################################
variable "mongodb_server_hostname" {
  description = "Hostname of the virtual instance (with MongoDB installed) to be deployed"
  default     = "mean-mongodb-vm"
}

variable "nodejs_server_hostname" {
  description = "Hostname of the virtual instance (with NodeJS, AngularJS and Express installed) to be deployed"
  default     = "mean-nodejs-vm"
}

variable "folder" {
  description = "Target vSphere folder for Virtual Machine"
  default     = ""
}

variable "datacenter" {
  description = "Target vSphere datacenter for Virtual Machine creation"
  default     = ""
}

variable "mongodb_server_vcpu" {
  description = "Number of Virtual CPU for the MongoDB server"
  default     = 1
}

variable "mongodb_server_memory" {
  description = "Memory for the MongoDB server in GBs"
  default     = 1
}

variable "nodejs_server_vcpu" {
  description = "Number of Virtual CPU for the NodeJs server; must not be less than 2 cores"
  default     = 2
}

variable "nodejs_server_memory" {
  description = "Memory for the NodeJs server in GBs; must not be less than 4GB"
  default     = 4
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

variable "mongodb_server_ipv4_address" {
  description = "IPv4 address for vNIC configuration in mongodb server"
}

variable "nodejs_server_ipv4_address" {
  description = "IPv4 address for vNIC configuration in nodejs server"
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

variable "mongodb_server_vm_template" {
  description = "Source VM or Template label for cloning to MongoDB server"
}

variable "mongodb_server_ssh_user" {
  description = "The user for ssh connection to MongoDB server, which is default in template"
  default     = "root"
}

variable "mongodb_server_ssh_user_password" {
  description = "The user password for ssh connection to MongoDB server, which is default in template"
}

variable "nodejs_server_vm_template" {
  description = "Source VM or Template label for cloning to NodeJs server"
}

variable "nodejs_server_ssh_user" {
  description = "The user for ssh connection to NodeJs server, which is default in template"
  default     = "root"
}

variable "nodejs_server_ssh_user_password" {
  description = "The user password for ssh connection to NodeJs server, which is default in template"
}

#variable "camc_private_ssh_key" {
#  description = "The base64 encoded private key for ssh connection"
#}

variable "user_public_key" {
  description = "User-provided public SSH key used to connect to the virtual machine"
  default     = "None"
}

##############################################################
# Create Virtual Machines
##############################################################
resource "vsphere_virtual_machine" "mongodb_vm" {
  name         = "${var.mongodb_server_hostname}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.mongodb_server_vcpu}"
  memory       = "${var.mongodb_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.mongodb_server_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.mongodb_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.mongodb_server_ssh_user}"
    password    = "${var.mongodb_server_ssh_user_password}"    
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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\""
    ]
  }
}

resource "vsphere_virtual_machine" "nodejs_vm" {
  name         = "${var.nodejs_server_hostname}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.nodejs_server_vcpu}"
  memory       = "${var.nodejs_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.nodejs_server_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.nodejs_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.nodejs_server_ssh_user}"
    password    = "${var.nodejs_server_ssh_user_password}"    
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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\""
    ]
  }
}

##############################################################
# Install MEAN
##############################################################
resource "null_resource" "install_mongodb"{

  # Specify the ssh connection
  connection {
    user        = "${var.mongodb_server_ssh_user}"
    password    = "${var.mongodb_server_ssh_user_password}"    
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${vsphere_virtual_machine.mongodb_vm.network_interface.0.ipv4_address}"
  }

  # Create the installation script
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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh"
    ]
  }
}

resource "null_resource" "install_nodejs"{
  depends_on    = ["null_resource.install_mongodb"]
  
  # Specify the ssh connection
  connection {
    user        = "${var.nodejs_server_ssh_user}"
    password    = "${var.nodejs_server_ssh_user_password}"    
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${vsphere_virtual_machine.nodejs_vm.network_interface.0.ipv4_address}"
  }

  # Create the installation script
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
curl -sL https://rpm.nodesource.com/setup_7.x | bash -                                                            >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install nodejs -y"                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
npm install -g bower gulp                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to install bower and gulp---" | tee -a $LOGFILE; exit 1; }

echo "---Install mean sample application---" | tee -a $LOGFILE 2>&1
retryInstall "yum install -y git"                                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to install git---" | tee -a $LOGFILE; exit 1; }
git clone https://github.com/meanjs/mean.git mean                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to clone mean sample project---" | tee -a $LOGFILE; exit 1; }
cd mean
yum groupinstall 'Development Tools' -y                                                                           >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
npm install                                                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to install node modules---" | tee -a $LOGFILE; exit 1; }
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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.mongodb_vm.network_interface.0.ipv4_address}\""
    ]
  }
}

##############################################################
# Check status
##############################################################
resource "null_resource" "check_status"{
  depends_on    = ["null_resource.install_nodejs"]
    
  # Specify the ssh connection
  connection {
    user        = "${var.nodejs_server_ssh_user}"
    password    = "${var.nodejs_server_ssh_user_password}"    
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${vsphere_virtual_machine.nodejs_vm.network_interface.0.ipv4_address}"
  }
  
  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

echo "---check application status---"

APP_URL=$1

TMPFILE=`mktemp tmp.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` && echo $TMPFILE

StatusCheckMaxCount=120
StatusCheckCount=0

curl -k -s -o /dev/null -w "%{http_code}" -I -m 5 $APP_URL > $TMPFILE || true
SERVICE_STATUS=$(cat $TMPFILE)

while [ "$SERVICE_STATUS" != "200" ]; do
	echo "---application is being started---"
	sleep 10
	let StatusCheckCount=StatusCheckCount+1	
	if [ $StatusCheckCount -eq $StatusCheckMaxCount ]; then
		echo "---The servce is not up---"
		rm -f $TMPFILE
		exit 1
	fi		
	curl -k -s -o /dev/null -w "%{http_code}" -I -m 5 $APP_URL > $TMPFILE || true
	SERVICE_STATUS=$(cat $TMPFILE)
done
rm -f $TMPFILE	
	
echo "---application is up---"

EOF
    destination = "/tmp/checkStatus.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/checkStatus.sh; bash /tmp/checkStatus.sh http://\"${vsphere_virtual_machine.nodejs_vm.network_interface.0.ipv4_address}\":8443"
    ]
  } 
}


#########################################################
# Output
#########################################################
output "Meanstack DB Server IP Address" {
  value = "${vsphere_virtual_machine.mongodb_vm.network_interface.0.ipv4_address}"
}

output "Meanstack NodeJS Server IP Address" {
  value = "${vsphere_virtual_machine.nodejs_vm.network_interface.0.ipv4_address}"
}

output "Please access the meanstack sample application" {
  value = "http://${vsphere_virtual_machine.nodejs_vm.network_interface.0.ipv4_address}:8443"
}
