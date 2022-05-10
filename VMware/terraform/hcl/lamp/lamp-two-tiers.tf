# This is a terraform generated template generated from twovmfinal

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
}

##############################################################
# Define pattern variables
##############################################################
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "mariadb_vm_datacenter" {
  name = var.mariadb_vm_datacenter
}

data "vsphere_datastore" "mariadb_vm_datastore" {
  name          = var.mariadb_vm_root_disk_datastore
  datacenter_id = data.vsphere_datacenter.mariadb_vm_datacenter.id
}

data "vsphere_resource_pool" "mariadb_vm_resource_pool" {
  name          = var.mariadb_vm_resource_pool
  datacenter_id = data.vsphere_datacenter.mariadb_vm_datacenter.id
}

data "vsphere_network" "mariadb_vm_network" {
  name          = var.mariadb_vm_network_interface_label
  datacenter_id = data.vsphere_datacenter.mariadb_vm_datacenter.id
}

data "vsphere_virtual_machine" "mariadb_vm_template" {
  name          = var.mariadb_vm_image
  datacenter_id = data.vsphere_datacenter.mariadb_vm_datacenter.id
}

##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "php_vm_datacenter" {
  name = var.php_vm_datacenter
}

data "vsphere_datastore" "php_vm_datastore" {
  name          = var.php_vm_root_disk_datastore
  datacenter_id = data.vsphere_datacenter.php_vm_datacenter.id
}

data "vsphere_resource_pool" "php_vm_resource_pool" {
  name          = var.php_vm_resource_pool
  datacenter_id = data.vsphere_datacenter.php_vm_datacenter.id
}

data "vsphere_network" "php_vm_network" {
  name          = var.php_vm_network_interface_label
  datacenter_id = data.vsphere_datacenter.php_vm_datacenter.id
}

data "vsphere_virtual_machine" "php_vm_template" {
  name          = var.php_vm_image
  datacenter_id = data.vsphere_datacenter.php_vm_datacenter.id
}

##### Image Parameters variables #####
#Variable : mariadb_vm_name
variable "mariadb_vm_name" {
  type        = string
  description = "Generated"
  default     = "mariadb-vm"
}

#Variable : php_vm_name
variable "php_vm_name" {
  type        = string
  description = "Generated"
  default     = "php-vm"
}

#########################################################
##### Resource : mariadb_vm
#########################################################

variable "mariadb_user" {
  description = "User to be added into db and sshed into servers"
  default     = "camuser"
}

variable "mariadb_ssh_user" {
  description = "The user for ssh connection to mariadb server, which is default in template"
  default     = "root"
}

variable "php_ssh_user" {
  description = "The user for ssh connection to php server, which is default in template"
  default     = "root"
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

variable "mariadb_vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "mariadb_vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "mariadb_vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "mariadb_vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default     = "1"
}

variable "mariadb_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "1024"
}

variable "mariadb_vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "mariadb_vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "mariadb_vm_dns_suffixes" {
  type        = list(string)
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "mariadb_vm_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
}

variable "mariadb_vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "mariadb_vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "mariadb_vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "mariadb_vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "mariadb_vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "mariadb_vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "mariadb_vm_root_disk_type" {
  type        = string
  description = "Type of template disk volume"
  default     = "eager_zeroed"
}

variable "mariadb_vm_root_disk_controller_type" {
  type        = string
  description = "Type of template disk controller"
  default     = "scsi"
}

variable "mariadb_vm_root_disk_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "mariadb_vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default     = "25"
}

variable "mariadb_vm_image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

module "provision_proxy_mariadb_vm" {
  source              = "./modules/proxy"
  ip                  = var.mariadb_vm_ipv4_address
  id                  = vsphere_virtual_machine.mariadb_vm.id
  ssh_user            = var.mariadb_ssh_user
  ssh_password        = var.mariadb_ssh_user_password
  http_proxy_host     = var.http_proxy_host
  http_proxy_user     = var.http_proxy_user
  http_proxy_password = var.http_proxy_password
  http_proxy_port     = var.http_proxy_port
  enable              = length(var.http_proxy_host) > 0 ? "true" : "false"
}

# vsphere vm
resource "vsphere_virtual_machine" "mariadb_vm" {
  name             = var.mariadb_vm_name
  folder           = var.mariadb_vm_folder
  num_cpus         = var.mariadb_vm_number_of_vcpu
  memory           = var.mariadb_vm_memory
  resource_pool_id = data.vsphere_resource_pool.mariadb_vm_resource_pool.id
  datastore_id     = data.vsphere_datastore.mariadb_vm_datastore.id
  guest_id         = data.vsphere_virtual_machine.mariadb_vm_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.mariadb_vm_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.mariadb_vm_template.id

    customize {
      linux_options {
        domain    = var.mariadb_vm_domain
        host_name = var.mariadb_vm_name
      }

      network_interface {
        ipv4_address = var.mariadb_vm_ipv4_address
        ipv4_netmask = var.mariadb_vm_ipv4_prefix_length
      }

      ipv4_gateway    = var.mariadb_vm_ipv4_gateway
      dns_suffix_list = var.mariadb_vm_dns_suffixes
      dns_server_list = var.mariadb_vm_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.mariadb_vm_network.id
    adapter_type = var.mariadb_vm_adapter_type
  }

  disk {
    label          = "${var.mariadb_vm_name}0.vmdk"
    size           = var.mariadb_vm_root_disk_size
    keep_on_remove = var.mariadb_vm_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.mariadb_vm_datastore.id
  }
}

#########################################################
##### Resource : php_vm
#########################################################

variable "php_vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "php_vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "php_vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "php_vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default     = "1"
}

variable "php_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "1024"
}

variable "php_vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "php_vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "php_vm_dns_suffixes" {
  type        = list(string)
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "php_vm_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
}

variable "php_vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "php_vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "php_vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "php_vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "php_vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "php_vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "php_vm_root_disk_type" {
  type        = string
  description = "Type of template disk volume"
  default     = "eager_zeroed"
}

variable "php_vm_root_disk_controller_type" {
  type        = string
  description = "Type of template disk controller"
  default     = "scsi"
}

variable "php_vm_root_disk_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "php_vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default     = "25"
}

variable "php_vm_image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

module "provision_proxy_php_vm" {
  source              = "./modules/proxy"
  ip                  = var.php_vm_ipv4_address
  id                  = vsphere_virtual_machine.php_vm.id
  ssh_user            = var.php_ssh_user
  ssh_password        = var.php_ssh_user_password
  http_proxy_host     = var.http_proxy_host
  http_proxy_user     = var.http_proxy_user
  http_proxy_password = var.http_proxy_password
  http_proxy_port     = var.http_proxy_port
  enable              = length(var.http_proxy_host) > 0 ? "true" : "false"
}

# vsphere vm
resource "vsphere_virtual_machine" "php_vm" {
  depends_on = [vsphere_virtual_machine.mariadb_vm]

  name             = var.php_vm_name
  folder           = var.php_vm_folder
  num_cpus         = var.php_vm_number_of_vcpu
  memory           = var.php_vm_memory
  resource_pool_id = data.vsphere_resource_pool.php_vm_resource_pool.id
  datastore_id     = data.vsphere_datastore.php_vm_datastore.id
  guest_id         = data.vsphere_virtual_machine.php_vm_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.php_vm_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.php_vm_template.id

    customize {
      linux_options {
        domain    = var.php_vm_domain
        host_name = var.php_vm_name
      }

      network_interface {
        ipv4_address = var.php_vm_ipv4_address
        ipv4_netmask = var.php_vm_ipv4_prefix_length
      }

      ipv4_gateway    = var.php_vm_ipv4_gateway
      dns_suffix_list = var.php_vm_dns_suffixes
      dns_server_list = var.php_vm_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.php_vm_network.id
    adapter_type = var.php_vm_adapter_type
  }

  disk {
    label           = "${var.php_vm_name}.vmdk"
    size           = var.php_vm_root_disk_size
    keep_on_remove = var.php_vm_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.php_vm_datastore.id
  }
}

resource "null_resource" "install_mariadb" {
  depends_on = [module.provision_proxy_mariadb_vm]

  # Specify the ssh connection
  # Specify the ssh connection
  connection {
    user                = var.mariadb_ssh_user
    password            = var.mariadb_ssh_user_password
    host                = vsphere_virtual_machine.mariadb_vm.clone[0].customize[0].network_interface[0].ipv4_address
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  # Create the installation script
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
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${var.mariadb_user}\" \"${var.mariadb_pwd}\" \"${vsphere_virtual_machine.php_vm.clone[0].customize[0].network_interface[0].ipv4_address}\"",
    ]
  }
}

resource "null_resource" "install_php" {
  depends_on = [
    null_resource.install_mariadb,
    module.provision_proxy_php_vm,
  ]

  # Specify the ssh connection
  # Specify the ssh connection
  connection {
    user                = var.php_ssh_user
    password            = var.php_ssh_user_password
    host                = vsphere_virtual_machine.php_vm.clone[0].customize[0].network_interface[0].ipv4_address
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  # Create the installation script
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
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.php_vm.clone[0].customize[0].network_interface[0].ipv4_address}\" \"${vsphere_virtual_machine.mariadb_vm.clone[0].customize[0].network_interface[0].ipv4_address}\" \"${var.mariadb_user}\" \"${var.mariadb_pwd}\"",
    ]
  }
}

output "vmware_php_address" {
  value = "http://${vsphere_virtual_machine.php_vm.clone[0].customize[0].network_interface[0].ipv4_address}/test.php"
}

output "mariadb_address" {
  value = vsphere_virtual_machine.mariadb_vm.clone[0].customize[0].network_interface[0].ipv4_address
}

