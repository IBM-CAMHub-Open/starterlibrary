#################################################################
# Terraform template that will deploy:
#    * MariaDB instance in one VM
#    * Apache and Php in another VM
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
  version              = "~> 0.4"
  allow_unverified_ssl = true
}

#########################################################
# Define the variables
#########################################################
variable "mariadb_server_hostname" {
  description = "Hostname of the virtual instance (with MariaDB installed) to be deployed"
  default     = "lamp-mariadb-vm"
}

variable "php_server_hostname" {
  description = "Hostname of the virtual instance (with Apache and PHP installed) to be deployed"
  default     = "lamp-php-vm"
}

variable "cam_user" {
  description = "User to be added into db and sshed into servers"
  default     = "camuser"
}

variable "cam_pwd" {
  description = "User password for cam user; It should be alphanumeric with length in [8,16]"
}

variable "folder" {
  description = "Target vSphere folder for Virtual Machine"
  default     = ""
}

variable "datacenter" {
  description = "Target vSphere datacenter for Virtual Machine creation"
  default     = ""
}

variable "mariadb_server_vcpu" {
  description = "Number of Virtual CPU for the MariaDB server"
  default     = 1
}

variable "mariadb_server_memory" {
  description = "Memory for the MariaDB server in GBs"
  default     = 1
}

variable "php_server_vcpu" {
  description = "Number of Virtual CPU for the PHP server"
  default     = 1
}

variable "php_server_memory" {
  description = "Memory for the PHP server in GBs"
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

variable "mariadb_server_ipv4_address" {
  description = "IPv4 address for vNIC configuration in mariadb server"
}

variable "php_server_ipv4_address" {
  description = "IPv4 address for vNIC configuration in php server"
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

variable "mariadb_server_vm_template" {
  description = "Source VM or Template label for cloning to MariaDB server"
}

variable "mariadb_server_ssh_user" {
  description = "The user for ssh connection to MariaDB server, which is default in template"
  default     = "root"
}

variable "mariadb_server_ssh_user_password" {
  description = "The user password for ssh connection to MariaDB server, which is default in template"
}

variable "php_server_vm_template" {
  description = "Source VM or Template label for cloning to PHP server"
}

variable "php_server_ssh_user" {
  description = "The user for ssh connection to PHP server, which is default in template"
  default     = "root"
}

variable "php_server_ssh_user_password" {
  description = "The user password for ssh connection to PHP server, which is default in template"
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
resource "vsphere_virtual_machine" "mariadb_vm" {
  name         = "${var.mariadb_server_hostname}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.mariadb_server_vcpu}"
  memory       = "${var.mariadb_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"

  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.mariadb_server_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.mariadb_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user     = "${var.mariadb_server_ssh_user}"
    password = "${var.mariadb_server_ssh_user_password}"

    #    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host = "${self.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\"",
    ]
  }
}

resource "vsphere_virtual_machine" "php_vm" {
  name         = "${var.php_server_hostname}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.php_server_vcpu}"
  memory       = "${var.php_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"

  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.php_server_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.php_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user     = "${var.php_server_ssh_user}"
    password = "${var.php_server_ssh_user_password}"

    #    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host = "${self.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\"",
    ]
  }
}

#########################################################
# Install LAMP
#########################################################
resource "null_resource" "install_mariadb" {
  # Specify the ssh connection
  connection {
    user     = "${var.mariadb_server_ssh_user}"
    password = "${var.mariadb_server_ssh_user_password}"

    #    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host = "${vsphere_virtual_machine.mariadb_vm.network_interface.0.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

LOGFILE="/var/log/install_mariadb.log"

USER=$1
PASSWORD=$2
HOST=$3

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

retryInstall "yum install -y mariadb mariadb-server"        >> $LOGFILE 2>&1 || { echo "---Failed to install MariaDB---" | tee -a $LOGFILE; exit 1; }
systemctl start mariadb                                     >> $LOGFILE 2>&1 || { echo "---Failed to start MariaDB---" | tee -a $LOGFILE; exit 1; }
systemctl enable mariadb                                    >> $LOGFILE 2>&1 || { echo "---Failed to enable MariaDB---" | tee -a $LOGFILE; exit 1; }

mysql -e "CREATE USER '$USER'@'$HOST' IDENTIFIED BY '$PASSWORD'; GRANT ALL PRIVILEGES ON * . * TO '$USER'@'$HOST'; FLUSH PRIVILEGES;"  >> $LOGFILE 2>&1 || { echo "---Failed to add user---" | tee -a $LOGFILE; exit 1; }

firewall-cmd --state >> $LOGFILE 2>&1
if [ $? -eq 0 ] ; then
  firewall-cmd --zone=public --add-port=3306/tcp --permanent  >> $LOGFILE 2>&1 || { echo "---Failed to open port 3306---" | tee -a $LOGFILE; exit 1; }
  firewall-cmd --reload                                       >> $LOGFILE 2>&1 || { echo "---Failed to reload firewall---" | tee -a $LOGFILE; exit 1; }
fi

echo "---finish installing mariaDB---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${var.cam_user}\" \"${var.cam_pwd}\" \"${vsphere_virtual_machine.php_vm.network_interface.0.ipv4_address}\"",
    ]
  }
}

resource "null_resource" "install_php" {
  depends_on = ["null_resource.install_mariadb"]

  # Specify the ssh connection
  connection {
    user     = "${var.php_server_ssh_user}"
    password = "${var.php_server_ssh_user_password}"

    #    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host = "${vsphere_virtual_machine.php_vm.network_interface.0.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

LOGFILE="/var/log/install_php.log"

PHP_HOST=$1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PWD=$4

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

echo "---start installing apache---" | tee -a $LOGFILE 2>&1
retryInstall "yum install -y httpd"                       >> $LOGFILE 2>&1 || { echo "---Failed to install apache---" | tee -a $LOGFILE; exit 1; }
systemctl start httpd                                     >> $LOGFILE 2>&1 || { echo "---Failed to start apache---" | tee -a $LOGFILE; exit 1; }
systemctl enable httpd                                    >> $LOGFILE 2>&1 || { echo "---Failed to enable apache---" | tee -a $LOGFILE; exit 1; }

firewall-cmd --state >> $LOGFILE 2>&1
if [ $? -eq 0 ] ; then
  firewall-cmd --zone=public --add-port=80/tcp --permanent  >> $LOGFILE 2>&1 || { echo "---Failed to open port 80---" | tee -a $LOGFILE; exit 1; }
  firewall-cmd --reload                                     >> $LOGFILE 2>&1 || { echo "---Failed to reload firewall---" | tee -a $LOGFILE; exit 1; }
fi
mkdir -p /var/www/html/$PHP_HOST/public_html              >> $LOGFILE 2>&1 || { echo "---Failed to create directory for web pages---" | tee -a $LOGFILE; exit 1; }
mkdir -p /var/log/httpd/$PHP_HOST/logs                    >> $LOGFILE 2>&1 || { echo "---Failed to create directory for apache logs---" | tee -a $LOGFILE; exit 1; }

cat << EOT > /etc/httpd/conf.d/virtualHost.conf
<Directory /var/www/html/$PHP_HOST/public_html>
    Require all granted
</Directory>
<VirtualHost *:80>
        ServerName $PHP_HOST
        ServerAdmin camadmin@localhost
        DocumentRoot /var/www/html/$PHP_HOST/public_html
        ErrorLog /var/log/httpd/$PHP_HOST/logs/error.log
        CustomLog /var/log/httpd/$PHP_HOST/logs/access.log combined
</VirtualHost>
EOT

systemctl restart httpd                                   >> $LOGFILE 2>&1 || { echo "---Failed to restart apache---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing apache---" | tee -a $LOGFILE 2>&1

echo "---start installing php---" | tee -a $LOGFILE 2>&1
retryInstall "yum install -y php php-mysql php-gd php-pear"  >> $LOGFILE 2>&1 || { echo "---Failed to install php---" | tee -a $LOGFILE; exit 1; }

cat << EOT > /var/www/html/$PHP_HOST/public_html/test.php
<html>
<head>
    <title>PHP Test</title>
</head>
    <body>
    <?php echo '<p>Thanks for trying the CAM Lamp stack starter pack</p>';
    // In the variables section below, replace user and password with your own MariaDB credentials as created on your server
    \$servername = "$MYSQL_HOST";
    \$username = "$MYSQL_USER";
    \$password = "$MYSQL_PWD";

    // Create MySQL connection
    \$conn = mysqli_connect(\$servername, \$username, \$password);

    // Check connection - if it fails, output will include the error message
    if (!\$conn) {
        die('<p>Connection failed: <p>' . mysqli_connect_error());
    }
    echo '<p>Connected successfully to MariaDB</p>';
    echo '<p>If you would like more information on IBM\'s cloud management products, checkout this <a href="https://www.ibm.com/cloud-computing/products/cloud-management/">link</a></p>';
    ?>
</body>
</html>
EOT

sestatus | grep 'enabled' >> $LOGFILE 2>&1
if [ $? == 0 ]; then
   setsebool -P httpd_can_network_connect=1                  >> $LOGFILE 2>&1 || { echo "---Failed to change SELinux permission---" | tee -a $LOGFILE; exit 1; }
fi

systemctl restart httpd                                   >> $LOGFILE 2>&1 || { echo "---Failed to restart apache---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing php---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.php_vm.network_interface.0.ipv4_address}\" \"${vsphere_virtual_machine.mariadb_vm.network_interface.0.ipv4_address}\" \"${var.cam_user}\" \"${var.cam_pwd}\"",
    ]
  }
}

#########################################################
# Output
#########################################################
output "IBM Cloud PHP address" {
  value = "http://${vsphere_virtual_machine.php_vm.network_interface.0.ipv4_address}/test.php"
}

output "MariaDB address" {
  value = "${vsphere_virtual_machine.mariadb_vm.network_interface.0.ipv4_address}"
}
