# This is a terraform generated template generated from twovmfinal

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

##############################################################
# Define pattern variables
##############################################################
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "mariadb-vm_datacenter" {
  name = "${var.mariadb-vm_datacenter}"
}
data "vsphere_datastore" "mariadb-vm_datastore" {
  name = "${var.mariadb-vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.mariadb-vm_datacenter.id}"
}
data "vsphere_resource_pool" "mariadb-vm_resource_pool" {
  name = "${var.mariadb-vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.mariadb-vm_datacenter.id}"
}
data "vsphere_network" "mariadb-vm_network" {
  name = "${var.mariadb-vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.mariadb-vm_datacenter.id}"
}

data "vsphere_virtual_machine" "mariadb-vm_template" {
  name = "${var.mariadb-vm-image}"
  datacenter_id = "${data.vsphere_datacenter.mariadb-vm_datacenter.id}"
}
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "php-vm_datacenter" {
  name = "${var.php-vm_datacenter}"
}
data "vsphere_datastore" "php-vm_datastore" {
  name = "${var.php-vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.php-vm_datacenter.id}"
}
data "vsphere_resource_pool" "php-vm_resource_pool" {
  name = "${var.php-vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.php-vm_datacenter.id}"
}
data "vsphere_network" "php-vm_network" {
  name = "${var.php-vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.php-vm_datacenter.id}"
}

data "vsphere_virtual_machine" "php-vm_template" {
  name = "${var.php-vm-image}"
  datacenter_id = "${data.vsphere_datacenter.php-vm_datacenter.id}"
}

##### Image Parameters variables #####
#Variable : mariadb-vm-name
variable "mariadb-vm-name" {
  type = "string"
  description = "Generated"
  default = "mariadb-vm"
}

#Variable : php-vm-name
variable "php-vm-name" {
  type = "string"
  description = "Generated"
  default = "php-vm"
}


#########################################################
##### Resource : mariadb-vm
#########################################################

variable "mariadb_user" {
  description = "User to be added into db and sshed into servers"
  default     = "camuser"
}

variable "mariadb_ssh_user" {
  description = "The user for ssh connection to mariadb server, which is default in template"
  default = "root"
}

variable "php_ssh_user" {
  description = "The user for ssh connection to php server, which is default in template"
  default = "root"
}

variable "mariadb_ssh_user_password" {
  description = "The user password for ssh connection to mariadb server, which is default in template"
}

variable "php_ssh_user_password" {
  description = "The user password for ssh connection to mariadb server, which is default in template"
}

variable "mariadb_pwd" {
  description = "User password for cam user; It should be alphanumeric with length in [8,16]"
}

variable "mariadb-vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "mariadb-vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "mariadb-vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "mariadb-vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "mariadb-vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}

variable "mariadb-vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "mariadb-vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "mariadb-vm_dns_suffixes" {
  type = "list"
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "mariadb-vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "mariadb-vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "mariadb-vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "mariadb-vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "mariadb-vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "mariadb-vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "mariadb-vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "mariadb-vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "mariadb-vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "mariadb-vm_root_disk_keep_on_remove" {
  type = "string"
  description = "Delete template disk volume when the virtual machine is deleted"
  default = "false"
}

variable "mariadb-vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}

variable "mariadb-vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

# vsphere vm
resource "vsphere_virtual_machine" "mariadb-vm" {
  name = "${var.mariadb-vm-name}"
  folder = "${var.mariadb-vm_folder}"
  num_cpus = "${var.mariadb-vm_number_of_vcpu}"
  memory = "${var.mariadb-vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.mariadb-vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.mariadb-vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.mariadb-vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.mariadb-vm_template.id}"
    customize {
      linux_options {
        domain = "${var.mariadb-vm_domain}"
        host_name = "${var.mariadb-vm-name}"
      }
    network_interface {
      ipv4_address = "${var.mariadb-vm_ipv4_address}"
      ipv4_netmask = "${var.mariadb-vm_ipv4_prefix_length}"
    }
    ipv4_gateway = "${var.mariadb-vm_ipv4_gateway}"
    dns_suffix_list = "${var.mariadb-vm_dns_suffixes}"
    dns_server_list = "${var.mariadb-vm_dns_servers}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.mariadb-vm_network.id}"
    adapter_type = "${var.mariadb-vm_adapter_type}"
  }

  disk {
    label = "${var.mariadb-vm-name}0.vmdk"
    size = "${var.mariadb-vm_root_disk_size}"
    keep_on_remove = "${var.mariadb-vm_root_disk_keep_on_remove}"
    datastore_id = "${data.vsphere_datastore.mariadb-vm_datastore.id}"
  }

}

#########################################################
##### Resource : php-vm
#########################################################

variable "php-vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "php-vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "php-vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "php-vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "php-vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}

variable "php-vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "php-vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "php-vm_dns_suffixes" {
  type = "list"
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "php-vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "php-vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "php-vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "php-vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "php-vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "php-vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "php-vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "php-vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "php-vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "php-vm_root_disk_keep_on_remove" {
  type = "string"
  description = "Delete template disk volume when the virtual machine is deleted"
  default = "false"
}

variable "php-vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}

variable "php-vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

# vsphere vm
resource "vsphere_virtual_machine" "php-vm" {

  depends_on = ["vsphere_virtual_machine.mariadb-vm"]

  name = "${var.php-vm-name}"
  folder = "${var.php-vm_folder}"
  num_cpus = "${var.php-vm_number_of_vcpu}"
  memory = "${var.php-vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.php-vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.php-vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.php-vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.php-vm_template.id}"
    customize {
      linux_options {
        domain = "${var.php-vm_domain}"
        host_name = "${var.php-vm-name}"
      }
    network_interface {
      ipv4_address = "${var.php-vm_ipv4_address}"
      ipv4_netmask = "${var.php-vm_ipv4_prefix_length}"
    }
    ipv4_gateway = "${var.php-vm_ipv4_gateway}"
    dns_suffix_list = "${var.php-vm_dns_suffixes}"
    dns_server_list = "${var.php-vm_dns_servers}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.php-vm_network.id}"
    adapter_type = "${var.php-vm_adapter_type}"
  }

  disk {
    name = "${var.php-vm-name}.vmdk"
    size = "${var.php-vm_root_disk_size}"
    keep_on_remove = "${var.php-vm_root_disk_keep_on_remove}"
    datastore_id = "${data.vsphere_datastore.php-vm_datastore.id}"
  }

}

resource "null_resource" "install_mariadb" {
  # Specify the ssh connection
  connection {
    user     = "${var.mariadb_ssh_user}"
    password = "${var.mariadb_ssh_user_password}"
    host = "${vsphere_virtual_machine.mariadb-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${var.mariadb_user}\" \"${var.mariadb_pwd}\" \"${vsphere_virtual_machine.php-vm.clone.0.customize.0.network_interface.0.ipv4_address}\"",
    ]
  }
}

resource "null_resource" "install_php" {
  depends_on = ["null_resource.install_mariadb"]

  # Specify the ssh connection
  connection {
    user     = "${var.php_ssh_user}"
    password = "${var.php_ssh_user_password}"
    host = "${vsphere_virtual_machine.php-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.php-vm.clone.0.customize.0.network_interface.0.ipv4_address}\" \"${vsphere_virtual_machine.mariadb-vm.clone.0.customize.0.network_interface.0.ipv4_address}\" \"${var.mariadb_user}\" \"${var.mariadb_pwd}\"",
    ]
  }
}

output "IBM Cloud PHP address" {
  value = "http://${vsphere_virtual_machine.php-vm.clone.0.customize.0.network_interface.0.ipv4_address}/test.php"
}

output "MariaDB address" {
  value = "${vsphere_virtual_machine.mariadb-vm.clone.0.customize.0.network_interface.0.ipv4_address}"
}
