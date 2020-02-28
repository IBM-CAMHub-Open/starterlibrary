#################################################################
# Terraform template that will deploy two VMs in AWS with LAMP
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
# ©Copyright IBM Corp. 2017, 2018.
#
##################################################################

#########################################################
# Define the AWS provider
#########################################################
provider "aws" {
  version = "~> 2.0"
  region  = "${var.aws_region}"
}

#########################################################
# Helper module for tagging
#########################################################
module "camtags" {
  source = "../Modules/camtags"
}

#########################################################
# Define the variables
#########################################################
variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-1"
}

#Variable : AWS image name
variable "aws_image" {
  type = "string"
  description = "Operating system image id / template that should be used when creating the virtual image"
  default = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "aws_ami_owner_id" {
  description = "AWS AMI Owner ID"
  default = "099720109477"
}

# Lookup for AMI based on image name and owner ID
data "aws_ami" "aws_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["${var.aws_image}*"]
  }
  owners = ["${var.aws_ami_owner_id}"]
}

variable "php_instance_name" {
  description = "The hostname of server with php"
  default     = "lampPhp"
}

variable "db_instance_name" {
  description = "The hostname of server with mysql"
  default     = "lampDb"
}

variable "network_name_prefix" {
  description = "The prefix of names for VPC, Gateway, Subnet and Security Group"
  default     = "opencontent-lamp"
}

variable "public_key_name" {
  description = "Name of the public SSH key used to connect to the servers"
  default     = "cam-public-key-lamp"
}

variable "public_key" {
  description = "Public SSH key used to connect to the servers"
}

variable "cam_user" {
  description = "User to be added into db and sshed into servers"
  default     = "camuser"
}

variable "cam_pwd" {
  description = "Password for cam user (minimal length is 8)"
}


#########################################################
# Build network
#########################################################
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-vpc"))}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-gateway"))}"
}

resource "aws_subnet" "primary" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}b"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-subnet"))}"
}

resource "aws_subnet" "secondary" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-subnet2"))}"
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.network_name_prefix}-db_subnet"
  subnet_ids = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-db_subnet"))}"
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-route-table"))}"
}

resource "aws_route_table_association" "primary" {
  subnet_id      = "${aws_subnet.primary.id}"
  route_table_id = "${aws_route_table.default.id}"
}

resource "aws_route_table_association" "secondary" {
  subnet_id      = "${aws_subnet.secondary.id}"
  route_table_id = "${aws_route_table.default.id}"
}

resource "aws_security_group" "application" {
  name        = "${var.network_name_prefix}-security-group-application"
  description = "Security group which applies to lamp application server"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-security-group-application"))}"
}

resource "aws_security_group" "database" {
  name        = "${var.network_name_prefix}-security-group-database"
  description = "Security group which applies to lamp mysql db"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-security-group-database"))}"
}

##############################################################
# Create user-specified public key in AWS
##############################################################
resource "aws_key_pair" "cam_public_key" {
  key_name   = "${var.public_key_name}"
  public_key = "${var.public_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "temp_public_key" {
  key_name   = "${var.public_key_name}-temp"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################
# Create a server for php
##############################################################
resource "aws_instance" "php_server" {
  depends_on                  = ["aws_route_table_association.primary", "aws_route_table_association.secondary"]
  instance_type               = "t2.micro"
  ami                         = "${data.aws_ami.aws_ami.id}"
  subnet_id                   = "${aws_subnet.primary.id}"
  vpc_security_group_ids      = ["${aws_security_group.application.id}"]
  key_name                    = "${aws_key_pair.temp_public_key.id}"
  associate_public_ip_address = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.php_instance_name}"))}"

  # Specify the ssh connection
  connection {
    user        = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.public_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"        
  }

  provisioner "file" {
    content = <<EOF
#!/bin/bash

LOGFILE="/var/log/addkey.log"
user_public_key=$1

if [ "$user_public_key" != "None" ] ; then
    echo "---start adding user_public_key----" | tee -a $LOGFILE 2>&1
    echo "$user_public_key" | tee -a $HOME/.ssh/authorized_keys          >> $LOGFILE 2>&1 || { echo "---Failed to add user_public_key---" | tee -a $LOGFILE; exit 1; }
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

LOGFILE="/var/log/createCAMUser.log"

apt-get update                                                                            >> $LOGFILE 2>&1 || { echo "---Failed to update---" | tee -a $LOGFILE; exit 1; }
apt-get install python-minimal -y                                                         >> $LOGFILE 2>&1 || { echo "---Failed to python-minimal---" | tee -a $LOGFILE; exit 1; }

echo "---start createCAMUser---" | tee -a $LOGFILE 2>&1

CAMUSER=$1
CAMPWD=$2

PASS=$(perl -e 'print crypt($ARGV[0], "password")' $CAMPWD)
useradd -m -s /bin/bash -p $PASS $CAMUSER                                                 >> $LOGFILE 2>&1 || { echo "---Failed to create user---" | tee -a $LOGFILE; exit 1; }
echo "$CAMUSER ALL=(ALL:ALL) NOPASSWD:ALL" | (EDITOR="tee -a" visudo)

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config     >> $LOGFILE 2>&1 || { echo "---Failed to config sshd---" | tee -a $LOGFILE; exit 1; }
echo "AllowUsers ubuntu $CAMUSER" >> /etc/ssh/sshd_config
service ssh restart                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to restart ssh---" | tee -a $LOGFILE; exit 1; }

echo "---finished creating CAMUser $CAMUSER---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/createCAMUser.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; sudo bash /tmp/addkey.sh \"${var.public_key}\"",
      "chmod +x /tmp/createCAMUser.sh; sudo bash /tmp/createCAMUser.sh \"${var.cam_user}\" \"${var.cam_pwd}\"",
    ]
  }
}

##############################################################
# Create a MySQL instance
##############################################################
resource "aws_db_instance" "mysql" {
  depends_on             = ["aws_route_table_association.primary", "aws_route_table_association.secondary"]
  allocated_storage      = "10"
  engine                 = "mysql"
  engine_version         = "5.6.34"
  instance_class         = "db.t2.micro"
  name                   = "${var.db_instance_name}"
  username               = "${var.cam_user}"
  password               = "${var.cam_pwd}"
  db_subnet_group_name   = "${aws_db_subnet_group.default.name}"
  parameter_group_name   = "default.mysql5.6"
  availability_zone      = "${var.aws_region}b"
  publicly_accessible    = true
  vpc_security_group_ids = ["${aws_security_group.database.id}"]
  skip_final_snapshot    = true
  tags                   = "${merge(module.camtags.tagsmap, map("Name", "${var.db_instance_name}"))}"
}

##############################################################
# Install Apache and PHP
##############################################################
resource "null_resource" "install_php" {
  # Specify the ssh connection
  connection {
    user        = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${aws_instance.php_server.public_ip}"
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
PUBLIC_MYSQL_DNS=$1
MYSQL_USER=$2
MYSQL_PWD=$3

PUBLIC_DNS=$(dig +short myip.opendns.com @resolver1.opendns.com)

echo "---my dns hostname is $PUBLIC_DNS---" | tee -a $LOGFILE 2>&1
hostnamectl set-hostname $PUBLIC_DNS                                  >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }

#update

echo "---update system---" | tee -a $LOGFILE 2>&1
apt-get update                                                        >> $LOGFILE 2>&1 || { echo "---Failed to update system---" | tee -a $LOGFILE; exit 1; }

echo "---install apache2---" | tee -a $LOGFILE 2>&1
apt-get install -y apache2                                            >> $LOGFILE 2>&1 || { echo "---Failed to install apache2---" | tee -a $LOGFILE; exit 1; }

echo "---set keepalive Off---" | tee -a $LOGFILE 2>&1
sed -i 's/KeepAlive On/KeepAlive Off/' /etc/apache2/apache2.conf      >> $LOGFILE 2>&1 || { echo "---Failed to config apache2---" | tee -a $LOGFILE; exit 1; }

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
a2dismod mpm_event                                                    >> $LOGFILE 2>&1 || { echo "---Failed to set mpm event---" | tee -a $LOGFILE; exit 1; }
a2enmod mpm_prefork                                                   >> $LOGFILE 2>&1 || { echo "---Failed to set mpm perfork---" | tee -a $LOGFILE; exit 1; }

echo "---restart apache2---" | tee -a $LOGFILE 2>&1
systemctl restart apache2                                             >> $LOGFILE 2>&1 || { echo "---Failed to restart apache2---" | tee -a $LOGFILE; exit 1; }

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
a2ensite $PUBLIC_DNS                                                  >> $LOGFILE 2>&1 || { echo "---Failed to setup virtual host---" | tee -a $LOGFILE; exit 1; }

echo "---setup helloworld.html---" | tee -a $LOGFILE 2>&1
cat << EOT > /var/www/html/$PUBLIC_DNS/public_html/helloworld.html
<!DOCTYPE html>
<html>
<body>
<h1>Hello world header</h1>
<p>Hello world, my FQDN is $PUBLIC_DNS</p>
</body>
</html>
EOT

echo "---disable default virtual host and restart apache2---" | tee -a $LOGFILE 2>&1
a2dissite 000-default.conf                                            >> $LOGFILE 2>&1 || { echo "---Failed to disable default virtual host---" | tee -a $LOGFILE; exit 1; }
systemctl restart apache2                                             >> $LOGFILE 2>&1 || { echo "---Failed to restart apache2---" | tee -a $LOGFILE; exit 1; }

echo "---install php packages---" | tee -a $LOGFILE 2>&1
apt-get install -y php7.0 php-pear libapache2-mod-php7.0 php7.0-mysql >> $LOGFILE 2>&1 || { echo "---Failed to install php packages---" | tee -a $LOGFILE; exit 1; }

mkdir /var/log/php
chown www-data /var/log/php

echo "---setup test.php---" | tee -a $LOGFILE 2>&1
cat << EOT > /var/www/html/$PUBLIC_DNS/public_html/test.php
<html>
<head>
    <title>PHP Test</title>
</head>
    <body>
    <?php echo '<p>Thanks for trying the CAM Lamp stack starter pack</p>';
    // In the variables section below, replace user and password with your own MySQL credentials as created on your server
    \$servername = "$PUBLIC_MYSQL_DNS";
    \$username = "$MYSQL_USER";
    \$password = "$MYSQL_PWD";

    // Create MySQL connection
    \$conn = mysqli_connect(\$servername, \$username, \$password);

    // Check connection - if it fails, output will include the error message
    if (!\$conn) {
        die('<p>Connection failed: <p>' . mysqli_connect_error());
    }
    echo '<p>Connected successfully to MySQL DB</p>';
    echo '<p>If you would like more information on IBM\'s cloud management products, checkout this <a href="https://www.ibm.com/cloud-computing/products/cloud-management/">link</a></p>';
    ?>
</body>
</html>
EOT

systemctl restart apache2                                             >> $LOGFILE 2>&1 || { echo "---Failed to restart apache2---" | tee -a $LOGFILE; exit 1; }
echo "---installed apache2 and php successfully---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh \"${aws_db_instance.mysql.address}\" \"${var.cam_user}\" \"${var.cam_pwd}\"",
    ]
  }
}

#########################################################
# Output
#########################################################
output "aws_php_address" {
  value = "http://${aws_instance.php_server.public_ip}/test.php"
}

output "mysql_address" {
  value = "${aws_db_instance.mysql.address}"
}
