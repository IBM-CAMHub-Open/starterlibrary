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
# Define the Azure provider
#########################################################
provider "azurerm" { }


#########################################################
# Helper module for tagging
#########################################################
module "camtags" {
  source = "../Modules/camtags"
}

#########################################################
# Define the variables
#########################################################
variable "azure_region" {
  description = "Azure region to deploy infrastructure resources"
  default     = "West US"
}

variable "name_prefix" {
  description = "Prefix of names for Azure resources"
  default     = "meanstack"
}

variable "admin_user" {
  description = "Name of an administrative user to be created in all virtual machines in this deployment"
  default     = "ibmadmin"
}

variable "admin_user_password" {
  description = "Password of the newly created administrative user"
}

variable "user_public_key" {
  description = "Public SSH key used to connect to the virtual machine"
  default     = "None"
}


#########################################################
# Deploy the network resources
#########################################################
resource "random_id" "default" {
  byte_length = "4"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.name_prefix}-${random_id.default.hex}-rg"
  location = "${var.azure_region}"
  tags     = "${module.camtags.tagsmap}"
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name_prefix}-${random_id.default.hex}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.default.name}"
}

resource "azurerm_subnet" "db" {
  name                 = "${var.name_prefix}-${random_id.default.hex}-subnet-db"
  resource_group_name  = "${azurerm_resource_group.default.name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet" "web" {
  name                 = "${var.name_prefix}-${random_id.default.hex}-subnet-web"
  resource_group_name  = "${azurerm_resource_group.default.name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "db" {
  name                         = "${var.name_prefix}-${random_id.default.hex}-db-pip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.default.name}"
  allocation_method 		   = "Static"
  tags                         = "${module.camtags.tagsmap}"
}

resource "azurerm_public_ip" "web" {
  name                         = "${var.name_prefix}-${random_id.default.hex}-web-pip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.default.name}"
  allocation_method 		   = "Static"
  tags                         = "${module.camtags.tagsmap}"
}

resource "azurerm_network_security_group" "db" {
  name                = "${var.name_prefix}-${random_id.default.hex}-db-nsg"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  tags                = "${module.camtags.tagsmap}"

  security_rule {
    name                       = "ssh-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "custom-tcp-allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "${azurerm_subnet.web.address_prefix}"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.name_prefix}-${random_id.default.hex}-web-nsg"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  tags                = "${module.camtags.tagsmap}"

  security_rule {
    name                       = "ssh-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "custom-tcp-allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "db" {
  name                      = "${var.name_prefix}-${random_id.default.hex}-db-nic1"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.default.name}"
  network_security_group_id = "${azurerm_network_security_group.db.id}"
  tags                      = "${module.camtags.tagsmap}"

  ip_configuration {
    name                          = "${var.name_prefix}-${random_id.default.hex}-db-nic1-ipc"
    subnet_id                     = "${azurerm_subnet.db.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.db.id}"
  }
}

resource "azurerm_network_interface" "web" {
  name                      = "${var.name_prefix}-${random_id.default.hex}-web-nic1"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.default.name}"
  network_security_group_id = "${azurerm_network_security_group.web.id}"
  tags                      = "${module.camtags.tagsmap}"

  ip_configuration {
    name                          = "${var.name_prefix}-${random_id.default.hex}-web-nic1-ipc"
    subnet_id                     = "${azurerm_subnet.web.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.web.id}"
  }
}

#########################################################
# Deploy the storage resources
#########################################################
resource "azurerm_storage_account" "default" {
  name                		= "${format("st%s",random_id.default.hex)}"
  resource_group_name 		= "${azurerm_resource_group.default.name}"
  location           	 	= "${var.azure_region}"
  account_tier        		= "Standard"  
  account_replication_type  = "LRS"
  
  tags                = "${module.camtags.tagsmap}"
  
}

resource "azurerm_storage_container" "default" {
  name                  = "default-container"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  storage_account_name  = "${azurerm_storage_account.default.name}"
  container_access_type = "private"
}

#########################################################
# Deploy the virtual machine resources
#########################################################
resource "azurerm_virtual_machine" "web" {
  count                 = "${var.user_public_key != "None" ? 1 : 0}"
  name                  = "${var.name_prefix}-${random_id.default.hex}-web-vm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  network_interface_ids = ["${azurerm_network_interface.web.id}"]
  vm_size               = "Standard_A2"
  tags                  = "${module.camtags.tagsmap}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-${random_id.default.hex}-web-os-disk1"
    vhd_uri       = "${azurerm_storage_account.default.primary_blob_endpoint}${azurerm_storage_container.default.name}/${var.name_prefix}-${random_id.default.hex}-web-os-disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-${random_id.default.hex}-web"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_user}/.ssh/authorized_keys"
      key_data = "${var.user_public_key}"
    }
  }
}

resource "azurerm_virtual_machine" "web-alternative" {
  count                 = "${var.user_public_key == "None" ? 1 : 0}"
  name                  = "${var.name_prefix}-${random_id.default.hex}-web-vm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  network_interface_ids = ["${azurerm_network_interface.web.id}"]
  vm_size               = "Standard_A2"
  tags                  = "${module.camtags.tagsmap}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-${random_id.default.hex}-web-os-disk1"
    vhd_uri       = "${azurerm_storage_account.default.primary_blob_endpoint}${azurerm_storage_container.default.name}/${var.name_prefix}-${random_id.default.hex}-web-os-disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-${random_id.default.hex}-web"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine" "db" {
  count                 = "${var.user_public_key != "None" ? 1 : 0}"
  name                  = "${var.name_prefix}-${random_id.default.hex}-db-vm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  network_interface_ids = ["${azurerm_network_interface.db.id}"]
  vm_size               = "Standard_A1"
  tags                  = "${module.camtags.tagsmap}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-${random_id.default.hex}-db-os-disk1"
    vhd_uri       = "${azurerm_storage_account.default.primary_blob_endpoint}${azurerm_storage_container.default.name}/${var.name_prefix}-${random_id.default.hex}-db-os-disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-${random_id.default.hex}-db"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_user}/.ssh/authorized_keys"
      key_data = "${var.user_public_key}"
    }
  }
}

resource "azurerm_virtual_machine" "db-alternative" {
  count                 = "${var.user_public_key == "None" ? 1 : 0}"
  name                  = "${var.name_prefix}-${random_id.default.hex}-db-vm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  network_interface_ids = ["${azurerm_network_interface.db.id}"]
  vm_size               = "Standard_A1"
  tags                  = "${module.camtags.tagsmap}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-${random_id.default.hex}-db-os-disk1"
    vhd_uri       = "${azurerm_storage_account.default.primary_blob_endpoint}${azurerm_storage_container.default.name}/${var.name_prefix}-${random_id.default.hex}-db-os-disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-${random_id.default.hex}-db"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

##############################################################
# Install MEAN
##############################################################
resource "null_resource" "install_mongodb" {
  depends_on = ["azurerm_virtual_machine.db", "azurerm_virtual_machine.db-alternative"]

  # Specify the ssh connection
  connection {
    user     = "${var.admin_user}"
    password = "${var.admin_user_password}"
    host     = "${azurerm_public_ip.db.ip_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_mongodb.log"

echo "---Install mongodb---" | tee -a $LOGFILE 2>&1

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6                                                      >> $LOGFILE 2>&1 || { echo "---Failed to obtain key for mongo---" | tee -a $LOGFILE; exit 1; }
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list    >> $LOGFILE 2>&1 || { echo "---Failed to add repo---" | tee -a $LOGFILE; exit 1; }
apt-get update                                                                                                                                             >> $LOGFILE 2>&1 || { echo "---Failed to update system---" | tee -a $LOGFILE; exit 1; }
apt-get install -y mongodb-org                                                                                                                             >> $LOGFILE 2>&1 || { echo "---Failed to install mongodb-org---" | tee -a $LOGFILE; exit 1; }

sed -i -e 's/  bindIp/#  bindIp/g' /etc/mongod.conf                                                                                                        >> $LOGFILE 2>&1 || { echo "---Failed to update mongod.conf---" | tee -a $LOGFILE; exit 1; }
service mongod start                                                                                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to start mongod service---" | tee -a $LOGFILE; exit 1; }

echo "---Done---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh",
    ]
  }
}

resource "null_resource" "install_nodejs" {
  depends_on = ["null_resource.install_mongodb", "azurerm_virtual_machine.web", "azurerm_virtual_machine.web-alternative"]

  # Specify the ssh connection
  connection {
    user     = "${var.admin_user}"
    password = "${var.admin_user_password}"
    host     = "${azurerm_public_ip.web.ip_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"
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

echo "---Install nodejs---" | tee -a $LOGFILE 2>&1
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -                                                    >> $LOGFILE 2>&1 || { echo "---Failed to run node script to set up repo---" | tee -a $LOGFILE; exit 1; }
apt-get install -y nodejs build-essential                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to install nodejs and build essential---" | tee -a $LOGFILE; exit 1; }
npm install -g bower gulp                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to install bower and gulp---" | tee -a $LOGFILE; exit 1; }

echo "---Install mean sample application---" | tee -a $LOGFILE 2>&1
git clone https://github.com/meanjs/mean.git mean                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to clone mean sample project---" | tee -a $LOGFILE; exit 1; }
cd mean
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

echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh \"${azurerm_network_interface.db.private_ip_address}\"",
    ]
  }
}

##############################################################
# Check status
##############################################################
resource "null_resource" "check_status" {
  depends_on = ["null_resource.install_nodejs"]

  # Specify the ssh connection
  connection {
    user     = "${var.admin_user}"
    password = "${var.admin_user_password}"
    host     = "${azurerm_public_ip.web.ip_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"
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
      "chmod +x /tmp/checkStatus.sh; sudo bash /tmp/checkStatus.sh http://\"${azurerm_public_ip.web.ip_address}\":8443",
    ]
  }
}

#########################################################
# Output
#########################################################
output "meanstack_web_vm_public_ip" {
  value = "${azurerm_public_ip.web.ip_address}"
}

output "meanstack_web_vm_private_ip" {
  value = "${azurerm_network_interface.web.private_ip_address}"
}

output "meanstack_db_vm_public_ip" {
  value = "${azurerm_public_ip.db.ip_address}"
}

output "meanstack_db_vm_private_ip" {
  value = "${azurerm_network_interface.db.private_ip_address}"
}

output "meanstack_sample_application_url" {
  value = "http://${azurerm_public_ip.web.ip_address}:8443"
}
