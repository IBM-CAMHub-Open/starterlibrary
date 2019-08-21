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
# ©Copyright IBM Corp. 2017, 2018.
#
##################################################################

#########################################################
# Define the AWS provider
#########################################################
provider "aws" {
  version = "~> 1.2"
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

variable "network_name_prefix" {
  description = "The prefix of names for VPC, Gateway, Subnet and Security Group"
  default     = "opencontent-meanstack"
}

variable "public_ssh_key_name" {
  description = "Name of the public SSH key used to connect to the virtual guests"
  default     = "cam-public-key-meanstack"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guests"
}

variable "hostname-db" {
  description = "The hostname of server with mongo"
  default     = "meanstack-db"
}

variable "hostname-nodejs" {
  description = "The hostname of server with nodejs"
  default     = "meanstack-nodejs"
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

resource "aws_subnet" "default" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.1.0/24"

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-subnet"))}"
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-route-table"))}"
}

resource "aws_route_table_association" "default" {
  subnet_id      = "${aws_subnet.default.id}"
  route_table_id = "${aws_route_table.default.id}"
}

resource "aws_security_group" "meanstack_mongo" {
  name        = "${var.network_name_prefix}-security-group-meanstack-mongo"
  description = "Security group which applies to meanstack servers with mongodb installed "
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-security-group-meanstack-mongo"))}"
}

resource "aws_security_group" "meanstack_nodejs" {
  name        = "${var.network_name_prefix}-security-group-meanstack-nodejs"
  description = "Security group which applies to meanstack servers with nodejs/angular/express installed "
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.network_name_prefix}-security-group-meanstack-nodejs"))}"
}

##############################################################
# Create user-specified public key in AWS
##############################################################
resource "aws_key_pair" "cam_public_key" {
  key_name   = "${var.public_ssh_key_name}"
  public_key = "${var.public_ssh_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "temp_public_key" {
  key_name   = "${var.public_ssh_key_name}-temp"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################
# Create a server for mongodb
##############################################################
resource "aws_instance" "mongodb_server" {
  depends_on                  = ["aws_route_table_association.default"]
  instance_type               = "t2.medium"
  ami                         = "${data.aws_ami.aws_ami.id}"
  subnet_id                   = "${aws_subnet.default.id}"
  vpc_security_group_ids      = ["${aws_security_group.meanstack_mongo.id}"]
  key_name                    = "${aws_key_pair.temp_public_key.id}"
  associate_public_ip_address = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.hostname-db}"))}"

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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; sudo bash /tmp/addkey.sh \"${var.public_ssh_key}\"",
    ]
  }
}

##############################################################
# Create a server for node.js, express and angular.js
##############################################################
resource "aws_instance" "nodejs_server" {
  depends_on                  = ["aws_route_table_association.default"]
  instance_type               = "t2.medium"
  ami                         = "${data.aws_ami.aws_ami.id}"
  subnet_id                   = "${aws_subnet.default.id}"
  vpc_security_group_ids      = ["${aws_security_group.meanstack_nodejs.id}"]
  key_name                    = "${aws_key_pair.temp_public_key.id}"
  associate_public_ip_address = true

  tags = "${merge(module.camtags.tagsmap, map("Name", "${var.hostname-nodejs}"))}"

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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/addkey.sh; sudo bash /tmp/addkey.sh \"${var.public_ssh_key}\"",
    ]
  }
}

##############################################################
# Install MEAN
##############################################################
resource "null_resource" "install_mongodb" {
  # Specify the ssh connection
  connection {
    user        = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${aws_instance.mongodb_server.public_ip}"
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
  depends_on = ["null_resource.install_mongodb"]

  # Specify the ssh connection
  connection {
    user        = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${aws_instance.nodejs_server.public_ip}"
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
      "chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh \"${aws_instance.mongodb_server.private_ip}\"",
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
    user        = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${aws_instance.nodejs_server.public_ip}"
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
      "chmod +x /tmp/checkStatus.sh; sudo bash /tmp/checkStatus.sh http://\"${aws_instance.nodejs_server.public_ip}\":8443",
    ]
  }
}

#########################################################
# Output
#########################################################
output "meanstack_db_server_ip_address" {
  value = "${aws_instance.mongodb_server.public_ip}"
}

output "meanstack_nodejs_server_ip_address" {
  value = "${aws_instance.nodejs_server.public_ip}"
}

output "meanstack_sample_application_url" {
  value = "http://${aws_instance.nodejs_server.public_ip}:8443"
}
