#################################################################
# Terraform template that will deploy three VMs with:
#    * StrongLoop in Strongloop-VM
#    * NodeJS in Strongloop-VM and Angular-VM
#    * AngularJS in Angular-VM
#    * MongoDB in MongoDB-VM
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
  allow_unverified_ssl = true
}

#########################################################
# Define the variables
#########################################################
variable "mongodb_server_hostname" {
  description = "Hostname of the virtual instance (with MongoDB installed) to be deployed"
  default     = "mongodb-vm"
}

variable "strongloop_server_hostname" {
  description = "Hostname of the virtual instance (with Strongloop and NodeJS installed) to be deployed"
  default     = "strongloop-vm"
}

variable "angularjs_server_hostname" {
  description = "Hostname of the virtual instance (with AngularJS and NodeJS installed) to be deployed"
  default     = "angularjs-vm"
}

variable "mongodb_user_password" {
  description = "The password of an user in mongodb for sample application; It should be alphanumeric with length in [8,16]"
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

variable "strongloop_server_vcpu" {
  description = "Number of Virtual CPU for the Strongloop server; must not be less than 2 cores"
  default     = 2
}

variable "strongloop_server_memory" {
  description = "Memory for the Strongloop server in GBs; must not be less than 4GB"
  default     = 4
}

variable "angularjs_server_vcpu" {
  description = "Number of Virtual CPU for the AngularJs server; must not be less than 2 cores"
  default     = 2
}

variable "angularjs_server_memory" {
  description = "Memory for the AngularJs server in GBs; must not be less than 4GB"
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

variable "strongloop_server_ipv4_address" {
  description = "IPv4 address for vNIC configuration in strongloop server"
}

variable "angularjs_server_ipv4_address" {
  description = "IPv4 address for vNIC configuration in angularjs server"
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

variable "strongloop_server_vm_template" {
  description = "Source VM or Template label for cloning to Strongloop server"
}

variable "strongloop_server_ssh_user" {
  description = "The user for ssh connection to Strongloop server, which is default in template"
  default     = "root"
}

variable "strongloop_server_ssh_user_password" {
  description = "The user password for ssh connection to Strongloop server, which is default in template"
}

variable "angularjs_server_vm_template" {
  description = "Source VM or Template label for cloning to AngularJs server"
}

variable "angularjs_server_ssh_user" {
  description = "The user for ssh connection to AngularJs server, which is default in template"
  default     = "root"
}

variable "angularjs_server_ssh_user_password" {
  description = "The user password for ssh connection to AngularJs server, which is default in template"
}

#variable "camc_private_ssh_key" {
#  description = "The base64 encoded private key for ssh connection"
#}

variable "user_public_key" {
  description = "User-provided public SSH key used to connect to the virtual machine"
  default     = "None"
}

##############################################################
# Create Virtual Machine and install MongoDB
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

#config mongodb
DBUserPwd=$1
echo "---start configuring mongodb---" | tee -a $LOGFILE 2>&1 
		
#create mongodb user and allow external access
sleep 30
mongo admin --eval "db.createUser({user: \"sampleUser\", pwd: \"$DBUserPwd\", roles: [{role: \"userAdminAnyDatabase\", db: \"admin\"}]})"    >> $LOGFILE 2>&1 || { echo "---Failed to create MongoDB user---" | tee -a $LOGFILE; exit 1; }
service mongod restart                                                                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to restart mongod---" | tee -a $LOGFILE; exit 1; }
				
echo "---finish configuring mongodb---" | tee -a $LOGFILE 2>&1 

if hash iptables 2>/dev/null; then
	#update firewall
	iptables -I INPUT 1 -p tcp -m tcp --dport 27017 -m conntrack --ctstate NEW -j ACCEPT                                                         >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }   
fi	

EOF
    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\"",
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${var.mongodb_user_password}\""
    ]
  }
}

##############################################################
# Create Virtual Machine for Strongloop
##############################################################
resource "vsphere_virtual_machine" "strongloop_vm" {
  name         = "${var.strongloop_server_hostname}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.strongloop_server_vcpu}"
  memory       = "${var.strongloop_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.strongloop_server_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.strongloop_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.strongloop_server_ssh_user}"
    password    = "${var.strongloop_server_ssh_user_password}"    
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
# Create Virtual Machine for AngularJS
##############################################################
resource "vsphere_virtual_machine" "angularjs_vm" {
  name         = "${var.angularjs_server_hostname}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.angularjs_server_vcpu}"
  memory       = "${var.angularjs_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.angularjs_server_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.angularjs_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.angularjs_server_ssh_user}"
    password    = "${var.angularjs_server_ssh_user_password}"    
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
# Install Strongloop
##############################################################
resource "null_resource" "install_strongloop"{
    
  # Specify the ssh connection
  connection {
    user        = "${var.strongloop_server_ssh_user}"
    password    = "${var.strongloop_server_ssh_user_password}"    
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${vsphere_virtual_machine.strongloop_vm.network_interface.0.ipv4_address}"
  }
  
  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_strongloop_nodejs.log"

MongoDB_Server=$1
DBUserPwd=$2

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

#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
retryInstall "yum install gcc-c++ make -y"                         >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_7.x | bash -             >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install nodejs -y"                               >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1 

#install strongloop

echo "---start installing strongloop---" | tee -a $LOGFILE 2>&1 
yum groupinstall 'Development Tools' -y                            >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
npm install -g strongloop                                          >> $LOGFILE 2>&1 || { echo "---Failed to install strongloop---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing strongloop---" | tee -a $LOGFILE 2>&1 

#install sample application

echo "---start installing sample application---" | tee -a $LOGFILE 2>&1 

PROJECT_NAME=sample
SAMPLE_DIR=$HOME/$PROJECT_NAME

retryInstall "yum install expect -y"                               >> $LOGFILE 2>&1 || { echo "---Failed to install Expect---" | tee -a $LOGFILE; exit 1; }

#create project
cd $HOME
SCRIPT_CREATE_PROJECT=createProject.sh	
cat << EOT > $SCRIPT_CREATE_PROJECT
#!/usr/bin/expect
set timeout 20
spawn slc loopback --skip-install $PROJECT_NAME
expect "name of your application"
send "\r"
expect "name of the directory"
send "\r"
expect "version of LoopBack"
send "\r"
expect "kind of application"
send "\r"
expect "Run the app"
send "\r"
close
EOT

chmod 755 $SCRIPT_CREATE_PROJECT                                   >> $LOGFILE 2>&1 || { echo "---Failed to change permission of script---" | tee -a $LOGFILE; exit 1; }
./$SCRIPT_CREATE_PROJECT                                           >> $LOGFILE 2>&1 || { echo "---Failed to execute script---" | tee -a $LOGFILE; exit 1; }
rm -f $SCRIPT_CREATE_PROJECT                                       >> $LOGFILE 2>&1 || { echo "---Failed to remove script---" | tee -a $LOGFILE; exit 1; }

#add dependency package 
cd $SAMPLE_DIR
sed -i -e '/loopback-datasource-juggler/a\ \ \ \ "loopback-connector-mongodb": "^1.18.0",' package.json    >> $LOGFILE 2>&1 || { echo "---Failed to add dependency for loopback-connector-mongo---" | tee -a $LOGFILE; exit 1; }
	
#install packages in server side
npm install                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install packages via npm---" | tee -a $LOGFILE; exit 1; }
	
#create data model
MODEL_NAME=Todos
SCRIPT_CREATE_MODEL=createModel.sh
cat << EOT > $SCRIPT_CREATE_MODEL
#!/usr/bin/expect
set timeout 20
spawn slc loopback:model $MODEL_NAME
expect "model name"
send "\r"
expect "data-source"
send "\r"
expect "base class"
send "\r"
expect "REST API"
send "\r"
expect "plural form"
send "\r"
expect "Common model"
send "\r"
expect "Property name"
send "content\r"
expect "Property type"
send "\r"
expect "Required"
send "\r"
expect "Default value"
send "\r"
expect "Property name"
send "\r"
close
EOT

chmod 755 $SCRIPT_CREATE_MODEL                                                          >> $LOGFILE 2>&1 || { echo "---Failed to change permission of script---" | tee -a $LOGFILE; exit 1; }
./$SCRIPT_CREATE_MODEL                                                                  >> $LOGFILE 2>&1 || { echo "---Failed to execute script---" | tee -a $LOGFILE; exit 1; }
rm -f $SCRIPT_CREATE_MODEL                                                              >> $LOGFILE 2>&1 || { echo "---Failed to remove script---" | tee -a $LOGFILE; exit 1; }

#update server config
DATA_SOURCE_FILE=server/datasources.json
sed -i -e 's/\ \ }/\ \ },/g' $DATA_SOURCE_FILE                                          >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e '/\ \ },/a\ \ "myMongoDB": {\n\ \ \ \ "host": "mongodb-server",\n\ \ \ \ "port": 27017,\n\ \ \ \ "url": "mongodb://sampleUser:sampleUserPwd@mongodb-server:27017/admin",\n\ \ \ \ "database": "Todos",\n\ \ \ \ "password": "sampleUserPwd",\n\ \ \ \ "name": "myMongoDB",\n\ \ \ \ "user": "sampleUser",\n\ \ \ \ "connector": "mongodb"\n\ \ }' $DATA_SOURCE_FILE    >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e "s/mongodb-server/$MongoDB_Server/g" $DATA_SOURCE_FILE                        >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e "s/sampleUserPwd/$DBUserPwd/g" $DATA_SOURCE_FILE                              >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
	
MODEL_CONFIG_FILE=server/model-config.json
sed -i -e '/Todos/{n;d}' $MODEL_CONFIG_FILE                                             >> $LOGFILE 2>&1 || { echo "---Failed to update model-config.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e '/Todos/a\ \ \ \ "dataSource": "myMongoDB",' $MODEL_CONFIG_FILE               >> $LOGFILE 2>&1 || { echo "---Failed to update model-config.json---" | tee -a $LOGFILE; exit 1; }


#make sample application as a service

SAMPLE_APP_SERVICE_CONF=/etc/systemd/system/nodeserver.service
cat << EOT > $SAMPLE_APP_SERVICE_CONF
[Unit]
Description=Node.js Example Server

[Service]
ExecStart=/usr/bin/node $SAMPLE_DIR/server/server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodejs-example
Environment=NODE_ENV=production PORT=3000

[Install]
WantedBy=multi-user.target
EOT
systemctl enable nodeserver.service                                                 >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
systemctl start nodeserver.service                                                  >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }

#update firewall
if hash iptables 2>/dev/null; then
	iptables -I INPUT 1 -p tcp -m tcp --dport 3000 -m conntrack --ctstate NEW -j ACCEPT     >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }   
fi
	
echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		

EOF
    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.mongodb_vm.network_interface.0.ipv4_address}\" \"${var.mongodb_user_password}\""
    ]
  } 
}

##############################################################
# Install AngularJs
##############################################################
resource "null_resource" "install_angularjs"{
    
  # Specify the ssh connection
  connection {
    user        = "${var.angularjs_server_ssh_user}"
    password    = "${var.angularjs_server_ssh_user_password}"    
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${vsphere_virtual_machine.angularjs_vm.network_interface.0.ipv4_address}"
  }
  
  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_angular_nodejs.log"

STRONGLOOP_SERVER=$1

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

#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
retryInstall "yum install gcc-c++ make -y"                                 >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_7.x | bash -                     >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install nodejs -y"                                       >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1 

#install angularjs

echo "---start installing angularjs---" | tee -a $LOGFILE 2>&1 
npm install -g grunt-cli bower yo generator-karma generator-angular        >> $LOGFILE 2>&1 || { echo "---Failed to install angular tools---" | tee -a $LOGFILE; exit 1; }

# enable repo to install ruby-devel
retryInstall "yum install -y yum-utils"                                    >> $LOGFILE 2>&1 || { echo "---Failed to install yum-config-manager---" | tee -a $LOGFILE; exit 1; }
yum-config-manager --enable rhel-7-server-optional-rpms                    >> $LOGFILE 2>&1 || { echo "---Failed to enable rhel-7-server-optional-rpms---" | tee -a $LOGFILE; exit 1; }

retryInstall "yum install gcc ruby ruby-devel rubygems make -y"            >> $LOGFILE 2>&1 || { echo "---Failed to install ruby---" | tee -a $LOGFILE; exit 1; }
gem install compass                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install compass---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing angularjs---" | tee -a $LOGFILE 2>&1 

#install sample application

echo "---start installing sample application---" | tee -a $LOGFILE 2>&1 

#create project
PROJECT_NAME=sample
SAMPLE_DIR=$HOME/$PROJECT_NAME
mkdir $SAMPLE_DIR

cd $SAMPLE_DIR

#make package.json
PACKAGE_JSON=package.json
cat << EOT > $PACKAGE_JSON
{
  "name": "angular-sample",
  "version": "1.0.0",
  "description": "Simple todo application.",
  "main": "server/server.js",
  "author": "UNKNOWN",
  "dependencies": {
    "body-parser": "^1.4.3",
    "express": "^4.13.4",
    "method-override": "^2.1.3"
  },
  "repository": {
    "type": "",
    "url": ""
  },
  "license": "UNLICENSED"
}
EOT

#make server.js
mkdir -p server
SERVER_JS_FILE=server/server.js
cat << EOT > $SERVER_JS_FILE
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var methodOverride = require('method-override'); 
var http = require('http');

app.use(bodyParser.json());
app.use(methodOverride());

app.get('/api/todos', function(req, res) {
    var optionsget = {
        host : 'strongloop-server',
        port : 3000,
        path : '/api/Todos',
        method : 'GET'
    };
    var reqGet = http.request(optionsget, function(res1) {
        res1.on('data', function(d) {
            res.send(d);
        });
    }); 
    reqGet.end();
    reqGet.on('error', function(e) {
        res.send(e);
    });
});

app.post('/api/todos', function(req, res) {
    jsonObject = JSON.stringify({
        "content" : req.body.content
    });  
    var postheaders = {
        'Content-Type' : 'application/json',
        'Accept' : 'application/json'
    }; 
    var optionspost = {
        host : 'strongloop-server',
        port : 3000,
        path : '/api/Todos',
        method : 'POST',
        headers : postheaders
    };  
    var reqPost = http.request(optionspost, function(res1) {
        res1.on('data', function(d) {
        });
    });
    reqPost.write(jsonObject);
    reqPost.end();
    reqPost.on('error', function(e) {
        console.error(e);
    });
    var optionsgetmsg = {
        host : 'strongloop-server',
        port : 3000,
        path : '/api/Todos',
        method : 'GET' 
    }; 
    // do the GET request
    var reqGet = http.request(optionsgetmsg, function(res2) {
        res2.on('data', function(d) {
            res.send(d);
        });
    });
    reqGet.end();
    reqGet.on('error', function(e) {
        console.error(e);
    });   
});

app.delete('/api/todos/:todo_id', function(req, res) {
    var postheaders = {
        'Accept' : 'application/json'
    };
    var optionsdelete = {
        host : 'strongloop-server',
        port : 3000,
        path : '/api/Todos/' + req.params.todo_id,
        method : 'DELETE',
        headers : postheaders
    };
    var reqDelete = http.request(optionsdelete, function(res1) {
        res1.on('data', function(d) {
        });
    });
    reqDelete.end();
    reqDelete.on('error', function(e) {
        console.error(e);
    });
    var optionsgetmsg = {
        host : 'strongloop-server', // here only the domain name
        port : 3000,
        path : '/api/Todos', // the rest of the url with parameters if needed
        method : 'GET' // do GET 
    };
    var reqGet = http.request(optionsgetmsg, function(res2) {
        res2.on('data', function(d) {
            res.send(d);
        });
    });
    reqGet.end();
    reqGet.on('error', function(e) {
        console.error(e);
    });
});
var path = require('path');
app.use(express.static(path.resolve(__dirname, '../client')));
app.listen(8080);
app.start = function() {
  return app.listen(function() {
  });
};
console.log("App listening on port 8080");
EOT

sed -i -e "s/strongloop-server/$STRONGLOOP_SERVER/g" $SERVER_JS_FILE                     >> $LOGFILE 2>&1 || { echo "---Failed to configure server.js---" | tee -a $LOGFILE; exit 1; } 

#install packages in server side
npm install                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to install packages via npm---" | tee -a $LOGFILE; exit 1; }

#install packages in client side
mkdir -p client
BOWERRC_FILE=.bowerrc
cat << EOT > $BOWERRC_FILE
{
  "directory": "client/vendor"
}
EOT

retryInstall "yum install -y git"                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install git---" | tee -a $LOGFILE; exit 1; }
bower install angular angular-resource angular-ui-router bootstrap --allow-root          >> $LOGFILE 2>&1 || { echo "---Failed to install packages via bower---" | tee -a $LOGFILE; exit 1; }
	
#add client files
INDEX_HTML=client/index.html
cat << EOT > $INDEX_HTML
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Strongloop Three-Tier Example</title>
    <link href="vendor/bootstrap/dist/css/bootstrap.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
  </head>
  <body ng-app="app">
    <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="#">Strongloop Three-Tier Example</a>
        </div>
      </div>
    </div>
    <div class="container">
      <div ui-view></div>
    </div>
    <script src="vendor/jquery/dist/jquery.js"></script>
    <script src="vendor/bootstrap/dist/js/bootstrap.js"></script>
    <script src="vendor/angular/angular.js"></script>
    <script src="vendor/angular-resource/angular-resource.js"></script>
    <script src="vendor/angular-ui-router/release/angular-ui-router.js"></script>
    <script src="js/app.js"></script>
    <script src="js/controllers/todo.js"></script>
  </body>
</html>
EOT

mkdir -p client/css
CSS_FILE=client/css/style.css
cat << EOT > $CSS_FILE
body {
 padding-top:50px;
}
.glyphicon-remove:hover {
 cursor:pointer;
}
EOT

mkdir -p client/js
APP_JS_FILE=client/js/app.js
cat << EOT > $APP_JS_FILE
angular
 .module('app', [
   'ui.router'
 ])
 .config(['\$stateProvider', '\$urlRouterProvider', function(\$stateProvider,
     \$urlRouterProvider) {
   \$stateProvider
     .state('todo', {
       url: '',
       templateUrl: 'js/views/todo.html',
       controller: 'TodoCtrl'
     });
   \$urlRouterProvider.otherwise('todo');
 }]);
EOT

mkdir -p client/js/views
VIEW_HTML=client/js/views/todo.html
cat << EOT > $VIEW_HTML
<h1>Todo list</h1>
<hr>
<form name="todoForm" novalidate ng-submit="addTodo()">
 <div class="form-group"
     ng-class="{'has-error': todoForm.content.\$invalid
       && todoForm.content.\$dirty}">
   <input type="text" class="form-control focus" name="content"
       placeholder="Content" autocomplete="off" required
       ng-model="newTodo.content">
   <span class="has-error control-label" ng-show="
       todoForm.content.\$invalid && todoForm.content.\$dirty">
     Content is required.
   </span>
 </div>
 <button class="btn btn-default" ng-disabled="todoForm.\$invalid">Add</button>
</form>
<hr>
<div class="list-group">
 <a class="list-group-item" ng-repeat="todo in todos">{{todo.content}}&nbsp;
   <i class="glyphicon glyphicon-remove pull-right"
       ng-click="removeTodo(todo)"></i></a>
</div>
EOT

mkdir -p client/js/controllers
CONTROLLER_JS_FILE=client/js/controllers/todo.js
cat << EOT > $CONTROLLER_JS_FILE
angular
 .module('app')
 .controller('TodoCtrl', ['\$scope', '\$state', '\$http', function(\$scope,
     \$state,\$http) {
   \$scope.todos = [];
   function getTodos() {        
     \$http({
        method: 'GET',
        url: 'api/todos'
     }).then(function (data){
        \$scope.todos = data.data;    
     },function (error){
        console.log('Error: ' + error);
     });  
   };
   getTodos();
 
   \$scope.addTodo = function() {
      \$http({
	method: 'POST',
        url: 'api/todos',
        headers: {'Content-Type': 'application/json'},
        data: {'content': \$scope.newTodo.content}
      }).then(function (success){
         \$scope.newTodo.content = '';
         \$scope.todoForm.content.\$setPristine();
         \$scope.todoForm.content.\$setUntouched();
         \$scope.todoForm.\$setPristine();
         \$scope.todoForm.\$setUntouched();
         \$('.focus').focus();
         getTodos();
     },function (error){
        console.log('Error: ' + error);
     });
   };
 
   \$scope.removeTodo = function(item) {
     \$http({
	method: 'DELETE',
        url: 'api/todos/'+item.id
     }).then(function (success){
        getTodos();
     },function (error){
        console.log('Error: ' + error);
     });
   };
 }]);
EOT

#make sample application as a service

SAMPLE_APP_SERVICE_CONF=/etc/systemd/system/nodeserver.service
cat << EOT > $SAMPLE_APP_SERVICE_CONF
[Unit]
Description=Node.js Example Server

[Service]
ExecStart=/usr/bin/node $SAMPLE_DIR/server/server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodejs-example
Environment=NODE_ENV=production PORT=8080

[Install]
WantedBy=multi-user.target
EOT
systemctl enable nodeserver.service                                       >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
systemctl start nodeserver.service                                        >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }

#update firewall
if hash iptables 2>/dev/null; then
	iptables -I INPUT 1 -p tcp -m tcp --dport 8080 -m conntrack --ctstate NEW -j ACCEPT     >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }   
fi

echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		

EOF
    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.strongloop_vm.network_interface.0.ipv4_address}\""
    ]
  } 
}

#########################################################
# Output
#########################################################
output "The mongodb server's ip addresses" {
    value = "${vsphere_virtual_machine.mongodb_vm.network_interface.0.ipv4_address}"
}

output "The strongloop server's ip addresses" {
    value = "${vsphere_virtual_machine.strongloop_vm.network_interface.0.ipv4_address}"
}

output "The angular server's ip addresses" {
    value = "${vsphere_virtual_machine.angularjs_vm.network_interface.0.ipv4_address}"
}

output "Please access the strongloop-three-tiers sample application using the following url" {
    value = "http://${vsphere_virtual_machine.angularjs_vm.network_interface.0.ipv4_address}:8080"
}
