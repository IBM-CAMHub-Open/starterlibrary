#################################################################
# Terraform template that will deploy LAMP in Microsoft Azure
#    * Virtual Machine - Ubuntu 16.04, Apache 2 and PHP 7.0
#    * SQL Server v12 Database Service
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
provider "azurerm" { version = "~> 1.0" }

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
  description = "Name of an administrative user to be created in virtual machine and SQL service in this deployment"
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

resource "azurerm_subnet" "web" {
  name                 = "${var.name_prefix}-subnet-${random_id.default.hex}-web"
  resource_group_name  = "${azurerm_resource_group.default.name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "web" {
  name                         = "${var.name_prefix}-${random_id.default.hex}-web-pip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.default.name}"
  allocation_method 		   = "Static"
  tags                         = "${module.camtags.tagsmap}"
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
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
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
  location            		= "${var.azure_region}"
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
# Deploy the virtual machine resource
#########################################################
resource "azurerm_virtual_machine" "web" {
  depends_on = ["azurerm_network_security_group.web", "azurerm_network_interface.web"]
  count                 = "${var.user_public_key != "None" ? 1 : 0}"
  name                  = "${var.name_prefix}-web-${random_id.default.hex}-vm"
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
  depends_on = ["azurerm_network_security_group.web", "azurerm_network_interface.web"]
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

#########################################################
# Deploy the SQL resource
#########################################################
resource "azurerm_sql_server" "db" {
  name                         = "${var.name_prefix}-${random_id.default.hex}-sqlserver"
  resource_group_name          = "${azurerm_resource_group.default.name}"
  location                     = "${var.azure_region}"
  version                      = "12.0"
  administrator_login          = "${var.admin_user}"
  administrator_login_password = "${var.admin_user_password}"
  tags                         = "${module.camtags.tagsmap}"
}

resource "azurerm_sql_database" "db" {
  name                = "${var.name_prefix}-${random_id.default.hex}-database"
  resource_group_name = "${azurerm_resource_group.default.name}"
  location            = "${var.azure_region}"
  server_name         = "${azurerm_sql_server.db.name}"
  tags                = "${module.camtags.tagsmap}"
}

resource "azurerm_sql_firewall_rule" "db" {
  name                = "allow-access-from-webserver"
  resource_group_name = "${azurerm_resource_group.default.name}"
  server_name         = "${azurerm_sql_server.db.name}"
  start_ip_address    = "${azurerm_public_ip.web.ip_address}"
  end_ip_address      = "${azurerm_public_ip.web.ip_address}"
}

##############################################################
# Install Apache and PHP
##############################################################
resource "null_resource" "install_php" {
  depends_on = ["azurerm_sql_firewall_rule.db", "azurerm_sql_database.db", "azurerm_virtual_machine.web", "azurerm_virtual_machine.web-alternative"]

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

LOGFILE="/var/log/installApache2.log"
PUBLIC_SQL_DNS=$1
SQL_USER=$2
SQL_PWD=$3
SQL_DATABASE=$4

PUBLIC_DNS=$(dig +short myip.opendns.com @resolver1.opendns.com)

echo "---my dns hostname is $PUBLIC_DNS---" | tee -a $LOGFILE 2>&1
hostnamectl set-hostname $PUBLIC_DNS                                                                                   >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }

#update

echo "---update system---" | tee -a $LOGFILE 2>&1
apt-get update                                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to update system---" | tee -a $LOGFILE; exit 1; }

echo "---install apache2---" | tee -a $LOGFILE 2>&1
apt-get install -y apache2                                                                                             >> $LOGFILE 2>&1 || { echo "---Failed to install apache2---" | tee -a $LOGFILE; exit 1; }

echo "---set keepalive Off---" | tee -a $LOGFILE 2>&1
sed -i 's/KeepAlive On/KeepAlive Off/' /etc/apache2/apache2.conf                                                       >> $LOGFILE 2>&1 || { echo "---Failed to config apache2---" | tee -a $LOGFILE; exit 1; }

echo "---enable mpm_prefork---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/apache2/mods-available/mpm_prefork.conf
<IfModule mpm_prefork_module>
        StartServers            4
        MinSpareServers         20
        MaxSpareServers         40
        MaxRequestWorkers       200
        MaxConnectionsPerChild  4500
</IfModule>
EOT
a2dismod mpm_event                                                                                                     >> $LOGFILE 2>&1 || { echo "---Failed to set mpm event---" | tee -a $LOGFILE; exit 1; }
a2enmod mpm_prefork                                                                                                    >> $LOGFILE 2>&1 || { echo "---Failed to set mpm perfork---" | tee -a $LOGFILE; exit 1; }

echo "---restart apache2---" | tee -a $LOGFILE 2>&1
systemctl restart apache2                                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to restart apache2---" | tee -a $LOGFILE; exit 1; }

echo "---setup virtual host---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/apache2/sites-available/$PUBLIC_DNS.conf
<Directory /var/www/html/$PUBLIC_DNS/public_html>
    Require all granted
</Directory>
<VirtualHost *:80>
        ServerName $PUBLIC_DNS
        ServerAdmin camadmin@localhost
        DocumentRoot /var/www/html/$PUBLIC_DNS/public_html
        ErrorLog /var/www/html/$PUBLIC_DNS/logs/error.log
        CustomLog /var/www/html/$PUBLIC_DNS/logs/access.log combined
</VirtualHost>
EOT
mkdir -p /var/www/html/$PUBLIC_DNS/{public_html,logs}
a2ensite $PUBLIC_DNS                                                                                                   >> $LOGFILE 2>&1 || { echo "---Failed to setup virtual host---" | tee -a $LOGFILE; exit 1; }

echo "---disable default virtual host and restart apache2---" | tee -a $LOGFILE 2>&1
a2dissite 000-default.conf                                                                                             >> $LOGFILE 2>&1 || { echo "---Failed to disable default virtual host---" | tee -a $LOGFILE; exit 1; }
systemctl restart apache2                                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to restart apache2---" | tee -a $LOGFILE; exit 1; }

echo "---install php packages---" | tee -a $LOGFILE 2>&1
apt-get install -y php7.0 libapache2-mod-php7.0 mcrypt php7.0-mcrypt php-mbstring php-pear php7.0-dev                  >> $LOGFILE 2>&1 || { echo "---Failed to install php packages---" | tee -a $LOGFILE; exit 1; }

echo "---install ODBC drive and SQL tools---" | tee -a $LOGFILE 2>&1
curl -s https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/mssql-tools.list    >> $LOGFILE 2>&1 || { echo "---Failed to update repo---" | tee -a $LOGFILE; exit 1; }
apt-get update                                                                                                         >> $LOGFILE 2>&1 || true
ACCEPT_EULA=Y apt-get install mssql-tools -y --allow-unauthenticated                                              >> $LOGFILE 2>&1 || { echo "---Failed to install mssql tools---" | tee -a $LOGFILE; exit 1; }
apt-get install unixodbc-dev -y --allow-unauthenticated                                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to install ODBC drive---" | tee -a $LOGFILE; exit 1; }
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

echo "---install php driver for SQL server---" | tee -a $LOGFILE 2>&1
pecl install sqlsrv-5.3.0 pdo_sqlsrv-5.3.0                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to install php drivers---" | tee -a $LOGFILE; exit 1; }
PHP_INI=/etc/php/7.0/apache2/php.ini
echo "extension= pdo_sqlsrv.so" | tee -a $PHP_INI                                                                      >> $LOGFILE 2>&1 || { echo "---Failed to update php_ini---" | tee -a $LOGFILE; exit 1; }
echo "extension= sqlsrv.so" | tee -a $PHP_INI                                                                          >> $LOGFILE 2>&1 || { echo "---Failed to update php_ini---" | tee -a $LOGFILE; exit 1; }

echo "---setup test.php---" | tee -a $LOGFILE 2>&1
cat << EOT > /var/www/html/$PUBLIC_DNS/public_html/test.php
<html>
<head>
    <title>PHP Test</title>
</head>
    <body>
    <?php echo '<p>Thanks for trying the CAM Lamp stack starter pack</p>';
    \$serverName = "$PUBLIC_SQL_DNS";
    \$connectionOptions = array(
        "Database" => "$SQL_DATABASE",
        "Uid" => "$SQL_USER",
        "PWD" => "$SQL_PWD"
    );
    \$conn = sqlsrv_connect(\$serverName, \$connectionOptions);

    // Check connection - if it fails, output will include the error message
    if (!\$conn) {
        die( print_r( sqlsrv_errors(), true));
    }
    echo '<p>Connected successfully to Azure SQL DB</p>';
    echo '<p>If you would like more information on IBM\'s cloud management products, checkout this <a href="https://www.ibm.com/cloud-computing/products/cloud-management/">link</a></p>';
    ?>
</body>
</html>
EOT

systemctl restart apache2                                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to restart apache2---" | tee -a $LOGFILE; exit 1; }

echo "---installed apache2 and php successfully---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh \"${azurerm_sql_server.db.fully_qualified_domain_name}\" \"${var.admin_user}\" \"${var.admin_user_password}\" \"${azurerm_sql_database.db.name}\"",
    ]
  }
}

#########################################################
# Output
#########################################################
output "lamp_web_vm_public_ip" {
  value = "${azurerm_public_ip.web.ip_address}"
}

output "lamp_web_vm_private_ip" {
  value = "${azurerm_network_interface.web.private_ip_address}"
}

output "lamp_sql_service_fqdn" {
  value = "${azurerm_sql_server.db.fully_qualified_domain_name}"
}

output "application_url" {
  value = "http://${azurerm_public_ip.web.ip_address}/test.php"
}
