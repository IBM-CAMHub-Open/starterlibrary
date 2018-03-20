# This is a terraform generated template generated from threefinal

##############################################################
# Keys - CAMC (public/private) & optional User Key (public)
##############################################################
variable "allow_unverified_ssl" {
  description = "Communication with vsphere server with self signed certificate"
  default = "true"
}

##############################################################
# Define the vsphere provider
##############################################################
provider "vsphere" {
  allow_unverified_ssl = "${var.allow_unverified_ssl}"
  version = "~> 1.3"
}

provider "camc" {
  version = "~> 0.2"
}

##############################################################
# Define pattern variables
##############################################################
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "angular-vm_datacenter" {
  name = "${var.angular-vm_datacenter}"
}
data "vsphere_datastore" "angular-vm_datastore" {
  name = "${var.angular-vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.angular-vm_datacenter.id}"
}
data "vsphere_resource_pool" "angular-vm_resource_pool" {
  name = "${var.angular-vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.angular-vm_datacenter.id}"
}
data "vsphere_network" "angular-vm_network" {
  name = "${var.angular-vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.angular-vm_datacenter.id}"
}

data "vsphere_virtual_machine" "angular-vm_template" {
  name = "${var.angular-vm-image}"
  datacenter_id = "${data.vsphere_datacenter.angular-vm_datacenter.id}"
}
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "mongodb-vm_datacenter" {
  name = "${var.mongodb-vm_datacenter}"
}
data "vsphere_datastore" "mongodb-vm_datastore" {
  name = "${var.mongodb-vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.mongodb-vm_datacenter.id}"
}
data "vsphere_resource_pool" "mongodb-vm_resource_pool" {
  name = "${var.mongodb-vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.mongodb-vm_datacenter.id}"
}
data "vsphere_network" "mongodb-vm_network" {
  name = "${var.mongodb-vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.mongodb-vm_datacenter.id}"
}

data "vsphere_virtual_machine" "mongodb-vm_template" {
  name = "${var.mongodb-vm-image}"
  datacenter_id = "${data.vsphere_datacenter.mongodb-vm_datacenter.id}"
}
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "strongloop-vm_datacenter" {
  name = "${var.strongloop-vm_datacenter}"
}
data "vsphere_datastore" "strongloop-vm_datastore" {
  name = "${var.strongloop-vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.strongloop-vm_datacenter.id}"
}
data "vsphere_resource_pool" "strongloop-vm_resource_pool" {
  name = "${var.strongloop-vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.strongloop-vm_datacenter.id}"
}
data "vsphere_network" "strongloop-vm_network" {
  name = "${var.strongloop-vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.strongloop-vm_datacenter.id}"
}

data "vsphere_virtual_machine" "strongloop-vm_template" {
  name = "${var.strongloop-vm-image}"
  datacenter_id = "${data.vsphere_datacenter.strongloop-vm_datacenter.id}"
}

##### Image Parameters variables #####

#Variable : angular-vm-name
variable "angular-vm-name" {
  type = "string"
  default = "angular-vm"
}

#Variable : mongodb-vm-name
variable "mongodb-vm-name" {
  type = "string"
  default = "mongodb-vm"
}

#Variable : strongloop-vm-name
variable "strongloop-vm-name" {
  type = "string"
  default = "strongloop-vm"
}


#########################################################
##### Resource : angular-vm
#########################################################

variable "mongodb_user_password" {
  description = "The password of an user in mongodb for sample application; It should be alphanumeric with length in [8,16]"
}

variable "angular-vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "angular-vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "angular-vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "angular-vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "angular-vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}

variable "angular-vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "angular-vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "angular-vm_dns_suffixes" {
  type = "list"
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "angular-vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "angular-vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "angular-vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "angular-vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "angular-vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "angular-vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "angular-vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "angular-vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "angular-vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "angular-vm_root_disk_keep_on_remove" {
  type = "string"
  description = "Delete template disk volume when the virtual machine is deleted"
  default = "false"
}

variable "angular-vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}

variable "angular-vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

# vsphere vm
resource "vsphere_virtual_machine" "angular-vm" {
  name = "${var.angular-vm-name}"
  folder = "${var.angular-vm_folder}"
  num_cpus = "${var.angular-vm_number_of_vcpu}"
  memory = "${var.angular-vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.angular-vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.angular-vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.angular-vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.angular-vm_template.id}"
    customize {
      linux_options {
        domain = "${var.angular-vm_domain}"
        host_name = "${var.angular-vm-name}"
      }
    network_interface {
      ipv4_address = "${var.angular-vm_ipv4_address}"
      ipv4_netmask = "${var.angular-vm_ipv4_prefix_length}"
    }
    ipv4_gateway = "${var.angular-vm_ipv4_gateway}"
    dns_suffix_list = "${var.angular-vm_dns_suffixes}"
    dns_server_list = "${var.angular-vm_dns_servers}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.angular-vm_network.id}"
    adapter_type = "${var.angular-vm_adapter_type}"
  }

  disk {
    label = "${var.angular-vm-name}0.vmdk"
    size = "${var.angular-vm_root_disk_size}"
    keep_on_remove = "${var.angular-vm_root_disk_keep_on_remove}"
    datastore_id = "${data.vsphere_datastore.angular-vm_datastore.id}"
  }

}

#########################################################
##### Resource : mongodb-vm
#########################################################

variable "mongodb_ssh_user" {
  description = "The user for ssh connection to MongoDB server, which is default in template"
  default     = "root"
}

variable "mongodb_ssh_user_password" {
  description = "The user password for ssh connection to MongoDB server, which is default in template"
}

variable "strongloop_ssh_user" {
  description = "The user for ssh connection to Strongloop server, which is default in template"
  default     = "root"
}

variable "strongloop_ssh_user_password" {
  description = "The user password for ssh connection to Strongloop server, which is default in template"
}

variable "angularjs_ssh_user" {
  description = "The user for ssh connection to AngularJs server, which is default in template"
  default     = "root"
}

variable "angularjs_ssh_user_password" {
  description = "The user password for ssh connection to AngularJs server, which is default in template"
}

variable "mongodb-vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "mongodb-vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "mongodb-vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "mongodb-vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "mongodb-vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}

variable "mongodb-vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "mongodb-vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "mongodb-vm_dns_suffixes" {
  type = "list"
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "mongodb-vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "mongodb-vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "mongodb-vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "mongodb-vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "mongodb-vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "mongodb-vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "mongodb-vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "mongodb-vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "mongodb-vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "mongodb-vm_root_disk_keep_on_remove" {
  type = "string"
  description = "Delete template disk volume when the virtual machine is deleted"
  default = "false"
}

variable "mongodb-vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}

variable "mongodb-vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

# vsphere vm
resource "vsphere_virtual_machine" "mongodb-vm" {
  name = "${var.mongodb-vm-name}"
  folder = "${var.mongodb-vm_folder}"
  num_cpus = "${var.mongodb-vm_number_of_vcpu}"
  memory = "${var.mongodb-vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.mongodb-vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.mongodb-vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.mongodb-vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.mongodb-vm_template.id}"
    customize {
      linux_options {
        domain = "${var.mongodb-vm_domain}"
        host_name = "${var.mongodb-vm-name}"
      }
    network_interface {
      ipv4_address = "${var.mongodb-vm_ipv4_address}"
      ipv4_netmask = "${var.mongodb-vm_ipv4_prefix_length}"
    }
    ipv4_gateway = "${var.mongodb-vm_ipv4_gateway}"
    dns_suffix_list = "${var.mongodb-vm_dns_suffixes}"
    dns_server_list = "${var.mongodb-vm_dns_servers}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.mongodb-vm_network.id}"
    adapter_type = "${var.mongodb-vm_adapter_type}"
  }

  disk {
    label = "${var.mongodb-vm-name}.vmdk"
    size = "${var.mongodb-vm_root_disk_size}"
    keep_on_remove = "${var.mongodb-vm_root_disk_keep_on_remove}"
    datastore_id = "${data.vsphere_datastore.mongodb-vm_datastore.id}"
  }

  connection {
    type = "ssh"
    user     = "${var.mongodb_ssh_user}"
    password = "${var.mongodb_ssh_user_password}"
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
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${var.mongodb_user_password}\"",
    ]
  }

}

#########################################################
##### Resource : strongloop-vm
#########################################################

variable "strongloop-vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "strongloop-vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "strongloop-vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "strongloop-vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "strongloop-vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}

variable "strongloop-vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "strongloop-vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "strongloop-vm_dns_suffixes" {
  type = "list"
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "strongloop-vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "strongloop-vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "strongloop-vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "strongloop-vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "strongloop-vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "strongloop-vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "strongloop-vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "strongloop-vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "strongloop-vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "strongloop-vm_root_disk_keep_on_remove" {
  type = "string"
  description = "Delete template disk volume when the virtual machine is deleted"
  default = "false"
}

variable "strongloop-vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}

variable "strongloop-vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

# vsphere vm
resource "vsphere_virtual_machine" "strongloop-vm" {
  name = "${var.strongloop-vm-name}"
  folder = "${var.strongloop-vm_folder}"
  num_cpus = "${var.strongloop-vm_number_of_vcpu}"
  memory = "${var.strongloop-vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.strongloop-vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.strongloop-vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.strongloop-vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.strongloop-vm_template.id}"
    customize {
      linux_options {
        domain = "${var.strongloop-vm_domain}"
        host_name = "${var.strongloop-vm-name}"
      }
    network_interface {
      ipv4_address = "${var.strongloop-vm_ipv4_address}"
      ipv4_netmask = "${var.strongloop-vm_ipv4_prefix_length}"
    }
    ipv4_gateway = "${var.strongloop-vm_ipv4_gateway}"
    dns_suffix_list = "${var.strongloop-vm_dns_suffixes}"
    dns_server_list = "${var.strongloop-vm_dns_servers}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.strongloop-vm_network.id}"
    adapter_type = "${var.strongloop-vm_adapter_type}"
  }

  disk {
    label = "${var.strongloop-vm-name}.vmdk"
    size = "${var.strongloop-vm_root_disk_size}"
    keep_on_remove = "${var.strongloop-vm_root_disk_keep_on_remove}"
    datastore_id = "${data.vsphere_datastore.strongloop-vm_datastore.id}"
  }

}

resource "null_resource" "install_strongloop" {
  # Specify the ssh connection
  connection {
    user     = "${var.strongloop_ssh_user}"
    password = "${var.strongloop_ssh_user_password}"
    host = "${vsphere_virtual_machine.strongloop-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.mongodb-vm.clone.0.customize.0.network_interface.0.ipv4_address}\" \"${var.mongodb_user_password}\"",
    ]
  }
}

resource "null_resource" "install_angularjs" {
  # Specify the ssh connection
  connection {
    user     = "${var.angularjs_ssh_user}"
    password = "${var.angularjs_ssh_user_password}"
    host = "${vsphere_virtual_machine.angular-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
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
yum groupinstall 'Development Tools' -y                            >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
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
bower install jquery angular angular-resource angular-ui-router bootstrap --allow-root          >> $LOGFILE 2>&1 || { echo "---Failed to install packages via bower---" | tee -a $LOGFILE; exit 1; }

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
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.strongloop-vm.clone.0.customize.0.network_interface.0.ipv4_address}\"",
    ]
  }
}


#########################################################
# Output
#########################################################
output "The mongodb server's ip addresses" {
  value = "${vsphere_virtual_machine.mongodb-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
}

output "The strongloop server's ip addresses" {
  value = "${vsphere_virtual_machine.strongloop-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
}

output "The angular server's ip addresses" {
  value = "${vsphere_virtual_machine.angular-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
}

output "Please access the strongloop-three-tiers sample application using the following url" {
  value = "http://${vsphere_virtual_machine.angular-vm.clone.0.customize.0.network_interface.0.ipv4_address}:8080"
}
