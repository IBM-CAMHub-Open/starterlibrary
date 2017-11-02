#################################################################
# Terraform template that will deploy one Pod in Kubernetes
#    * Nginx Pod
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
# Define the ibmcloud provider
#########################################################
provider "ibm" {
  version = "~> 0.5"
}

#########################################################
# Define the variables
#########################################################
variable "clustername" {
    description = "Cluster name"
}

variable "count" {
    description = "Number of managed nodes"
}

variable "datacenter" {
    description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "public_ssh_key" {
    description = "public ssh key to add to each kubernetes host virtual machine"
}

variable "mongodb_user_password" {
    description = "The password of an user (sampleUser) in mongodb for sample application"
}

##############################################################
# Create public key in Devices>Manage>SSH Keys in SL console
##############################################################
resource "ibm_compute_ssh_key" "cam_public_key" {
    label      = "CAM Public Key"
    public_key = "${var.public_ssh_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "temp_public_key" {
  label      = "Temp Public Key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################
# Create Virtual Machine for Kubernetes Master
##############################################################
resource "ibm_compute_vm_instance" "kubernetes_master_vm" {
  hostname                 = "${var.clustername}"
  os_reference_code        = "CENTOS_7_64"
  domain                   = "cam.ibm.com"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = 2
  memory                   = 4096
  disks                    = [25]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
}

##############################################################
# Create Virtual Machine for Kubernetes Nodes
##############################################################
resource "ibm_compute_vm_instance" "kuberentes_node_vm" {
  count                    = "${var.count}"
  hostname                 = "${format("${var.clustername}-%d", count.index+1)}"
  os_reference_code        = "CENTOS_7_64"
  domain                   = "cam.ibm.com"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = 2
  memory                   = 4096
  disks                    = [25]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
}

##############################################################
# Install Kuberentes Master
##############################################################
resource "null_resource" "install_kubernetes_master"{

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
	host        = "${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_kubernetes_master.log"

# Bypass ip chekcer
bypassIPChecker () {
  echo $1.$2.$3.$4
}
ATOM_NETWORK_IP=$(bypassIPChecker 172 17 0 0)
BIND_IP=$(bypassIPChecker 0 0 0 0)
CLUSTER_IP=$(bypassIPChecker 10 10 10 0)

# Set up hostname and obtain IP
echo "---start hostname, ip address setup---" | tee -a $LOGFILE 2>&1
yum install curl -y                                                   >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
yum install bind-utils -y                                             >> $LOGFILE 2>&1 || { echo "---Failed to install bind-utils---" | tee -a $LOGFILE; exit 1; }

MYIP=$(ip addr show eth1 | grep 'scope global eth1' | tr -s ' ' | cut -d' ' -f 3 | cut -d \/ -f 1)
echo "---master node ip address is $MYIP---" | tee -a $LOGFILE 2>&1

MYHOSTNAME=$(dig -x $MYIP +short | sed -e 's/.$//')
echo "---master node dns hostname is $MYHOSTNAME---" | tee -a $LOGFILE 2>&1

hostnamectl set-hostname $MYHOSTNAME                                  >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }
echo "---start installing kubernetes master node on $MYHOSTNAME---" | tee -a $LOGFILE 2>&1 

# install packages
systemctl disable firewalld                                           >> $LOGFILE 2>&1 || { echo "---Failed to disable firewall---" | tee -a $LOGFILE; exit 1; }
systemctl stop firewalld                                              >> $LOGFILE 2>&1 || { echo "---Failed to stop firewall---" | tee -a $LOGFILE; exit 1; }
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   >> $LOGFILE 2>&1 || { echo "---Failed to config selinux---" | tee -a $LOGFILE; exit 1; }
setenforce 0                                                          >> $LOGFILE 2>&1 || { echo "---Failed to set enforce---" | tee -a $LOGFILE; exit 1; }
yum install etcd -y                                                   >> $LOGFILE 2>&1 || { echo "---Failed to install etcd---" | tee -a $LOGFILE; exit 1; }
yum install flannel -y                                                >> $LOGFILE 2>&1 || { echo "---Failed to install flannel---" | tee -a $LOGFILE; exit 1; }
yum install kubernetes -y                                             >> $LOGFILE 2>&1 || { echo "---Failed to install kubernetes---" | tee -a $LOGFILE; exit 1; }

# configure etcd
echo "---start to write etcd config to /etc/etcd/etcd.conf---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/etcd/etcd.conf
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://$BIND_IP:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://$BIND_IP:2379"
EOT

# start etcd and define flannel network
echo "---starting etcd and using etcdctl mk---" | tee -a $LOGFILE 2>&1
systemctl start etcd                                                         >> $LOGFILE 2>&1 || { echo "---Failed to start etcd---" | tee -a $LOGFILE; exit 1; }
systemctl status etcd                                                        >> $LOGFILE 2>&1 || { echo "---Failed to check etcd status---" | tee -a $LOGFILE; exit 1; }
sleep 5
etcdctl mk /atomic.io/network/config '{"Network":"'$ATOM_NETWORK_IP'/16"}'   >> $LOGFILE 2>&1 || { echo "---Failed to run etcdctl---" | tee -a $LOGFILE; exit 1; }

# configure kubernetes apiserver
echo "---start to write apiserver config to /etc/kubernetes/apiserver---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/kubernetes/apiserver
KUBE_API_ADDRESS="--insecure-bind-address=$BIND_IP"
KUBE_ETCD_SERVERS="--etcd-servers=http://$MYHOSTNAME:2379"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=$CLUSTER_IP/24"
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"
KUBE_API_ARGS=""
EOT

# configure base kubernetes
echo "---start to write kubernetes config to /etc/kubernetes/config---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=http://$MYHOSTNAME:8080"
EOT

# configure flannel to use network defined and stored in etcd
echo "---start to write flannel config to /etc/sysconfig/flanneld---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://$MYHOSTNAME:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
EOT

# start all the required services
echo "---starting etcd kube-apiserver kube-controller-manager kube-scheduler kube-proxy docker flanneld---" | tee -a $LOGFILE 2>&1
for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler kube-proxy docker flanneld; do
    systemctl restart $SERVICES                                    >> $LOGFILE 2>&1 || { echo "---Failed to restart service---" | tee -a $LOGFILE; exit 1; }
    systemctl enable $SERVICES                                     >> $LOGFILE 2>&1 || { echo "---Failed to enable service---" | tee -a $LOGFILE; exit 1; }
    sleep 5
    systemctl status $SERVICES                                     >> $LOGFILE 2>&1 || { echo "---Failed to check service status---" | tee -a $LOGFILE; exit 1; }
done

echo "---kubernetes master node installed successfully---" | tee -a $LOGFILE 2>&1

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

######################################################################
# Install Kuberentes Nodes and copy strongloop installation script
######################################################################
resource "null_resource" "install_kubernetes_node"{
  depends_on    = ["null_resource.install_kubernetes_master"]
  count         = "${var.count}"

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
	host        = "${element(ibm_compute_vm_instance.kuberentes_node_vm.*.ipv4_address,count.index)}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
#set -o nounset
set -o pipefail

LOGFILE="/var/log/install_kubernetes_minion.log"

MASTERIP=$1

# Bypass ip checker
bypassIPChecker () {
  echo $1.$2.$3.$4
}
BIND_IP=$(bypassIPChecker 0 0 0 0)

# Set up hostname and obtain IP
echo "---start hostname, ip address setup---" | tee -a $LOGFILE 2>&1
yum install curl -y                                                   >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
yum install bind-utils -y                                             >> $LOGFILE 2>&1 || { echo "---Failed to install bind-utils---" | tee -a $LOGFILE; exit 1; }

MYIP=$(ip addr show eth1 | grep 'scope global eth1' | tr -s ' ' | cut -d' ' -f 3 | cut -d \/ -f 1)
echo "---minion node ip address is $MYIP---" | tee -a $LOGFILE 2>&1

MYHOSTNAME=$(dig -x $MYIP +short | sed -e 's/.$//')
echo "---minion node dns hostname is $MYHOSTNAME---" | tee -a $LOGFILE 2>&1

hostnamectl set-hostname $MYHOSTNAME                                  >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }

MASTER=$(dig -x $MASTERIP +short | sed -e 's/.$//')
echo "---master node hostname is $MASTER---" | tee -a $LOGFILE 2>&1

echo "---start installing kubernetes minion node on $MYHOSTNAME---" | tee -a $LOGFILE 2>&1 

# install packages
systemctl disable firewalld                                           >> $LOGFILE 2>&1 || { echo "---Failed to disable firewall---" | tee -a $LOGFILE; exit 1; }
systemctl stop firewalld                                              >> $LOGFILE 2>&1 || { echo "---Failed to stop firewall---" | tee -a $LOGFILE; exit 1; }
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   >> $LOGFILE 2>&1 || { echo "---Failed to config selinux---" | tee -a $LOGFILE; exit 1; }
setenforce 0                                                          >> $LOGFILE 2>&1 || { echo "---Failed to set enforce---" | tee -a $LOGFILE; exit 1; }
yum install flannel -y                                                >> $LOGFILE 2>&1 || { echo "---Failed to install flannel---" | tee -a $LOGFILE; exit 1; }
yum install kubernetes -y                                             >> $LOGFILE 2>&1 || { echo "---Failed to install kubernetes---" | tee -a $LOGFILE; exit 1; }

# configure base kubernetes
echo "---start to write kubernetes config to /etc/kubernetes/config---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=http://$MASTER:8080"
EOT

# configure flannel to use network defined and stored in etcd
echo "---start to write flannel config to /etc/sysconfig/flanneld---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://$MASTER:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
EOT

# configure flannel to use network defined and stored in etcd
echo "---start to write kublet config to /etc/kubernetes/kubelet---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=$BIND_IP"
KUBELET_HOSTNAME="--hostname-override=$MYHOSTNAME"
KUBELET_API_SERVER="--api-servers=http://$MASTER:8080"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
KUBELET_ARGS=""
EOT

# start all the required services
echo "---starting kube-proxy kubelet flanneld docker---" | tee -a $LOGFILE 2>&1
for SERVICES in kube-proxy kubelet flanneld docker; do
    systemctl restart $SERVICES                                     >> $LOGFILE 2>&1 || { echo "---Failed to restart service---" | tee -a $LOGFILE; exit 1; }
    systemctl enable $SERVICES                                      >> $LOGFILE 2>&1 || { echo "---Failed to enable service---" | tee -a $LOGFILE; exit 1; }
    sleep 5
    systemctl status $SERVICES                                      >> $LOGFILE 2>&1 || { echo "---Failed to check service status---" | tee -a $LOGFILE; exit 1; }
done

echo "---kubernetes minion node installed successfully---" | tee -a $LOGFILE 2>&1

EOF
    destination = "/tmp/installation.sh"
  }

  # Copy installStrongloop script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_strongloop_nodejs.log"

MongoDB_Server=$1
DBUserPwd=$2

#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
yum install gcc-c++ make -y                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_7.x | bash -                             >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
yum install nodejs -y                                                              >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
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

yum install expect -y                                              >> $LOGFILE 2>&1 || { echo "---Failed to install Expect---" | tee -a $LOGFILE; exit 1; }

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

slc run $SAMPLE_DIR &                                                                   >> $LOGFILE 2>&1 || { echo "---Failed to start the application---" | tee -a $LOGFILE; exit 1; }
		
echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		

EOF
    destination = "/tmp/installStrongloop.sh"
  }

  # Copy installAngularJs script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_angular_nodejs.log"

STRONGLOOP_SERVER=$1

#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
yum install gcc-c++ make -y                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_7.x | bash -                             >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
yum install nodejs -y                                                              >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1 

#install angularjs

echo "---start installing angularjs---" | tee -a $LOGFILE 2>&1 
npm install -g grunt-cli bower yo generator-karma generator-angular        >> $LOGFILE 2>&1 || { echo "---Failed to install angular tools---" | tee -a $LOGFILE; exit 1; }
yum install gcc ruby ruby-devel rubygems make -y                           >> $LOGFILE 2>&1 || { echo "---Failed to install ruby---" | tee -a $LOGFILE; exit 1; }
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
app.listen(8090);
app.start = function() {
  return app.listen(function() {
  });
};
console.log("App listening on port 8090");
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

yum install -y git                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to install git---" | tee -a $LOGFILE; exit 1; }
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

node $SAMPLE_DIR/server/server.js &                                       >> $LOGFILE 2>&1 || { echo "---Failed to start the application---" | tee -a $LOGFILE; exit 1; }

echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		

EOF
    destination = "/tmp/installAngularJs.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}\"",
      "chmod +x /tmp/installStrongloop.sh",
      "chmod +x /tmp/installAngularJs.sh"      
    ]
  }
}

##############################################################
# Install Dashboard
##############################################################
resource "null_resource" "install_dashboard"{
  depends_on    = ["null_resource.install_kubernetes_node"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
	host        = "${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_kubernetes_dashboard.log"

MYIP=$(hostname --ip-address)

# install the kubernetes-dashboard
echo "---install the kubernetes-dashboard---" | tee -a $LOGFILE 2>&1

curl -O https://raw.githubusercontent.com/kubernetes/dashboard/v1.6.3/src/deploy/kubernetes-dashboard.yaml                     >> $LOGFILE 2>&1 || { echo "---Failed to download kubernetes dashboard yaml---" | tee -a $LOGFILE; exit 1; }
sed -i "s/# - --apiserver-host=http:\/\/my-address:port/- --apiserver-host=http:\/\/$MYIP:8080/g" kubernetes-dashboard.yaml    >> $LOGFILE 2>&1 || { echo "---Failed to update kubernetes dashboard yaml---" | tee -a $LOGFILE; exit 1; }

kubectl create -f kubernetes-dashboard.yaml --validate=false  || true                                                          >> $LOGFILE 2>&1

echo "---check dashboard deployment status---" | tee -a $LOGFILE 2>&1

DashboardPodStatus=$(kubectl get pods --namespace kube-system | grep "kubernetes-dashboard" | awk 'NR == 1' | awk '{print $3}')
StatusCheckMaxCount=120
StatusCheckCount=0
while [ "$DashboardPodStatus" != "Running" ]; do
	echo "---Check $StatusCheckCount: $DashboardPodStatus---" | tee -a $LOGFILE 2>&1
	sleep 10
	let StatusCheckCount=StatusCheckCount+1
	if [ $StatusCheckCount -eq $StatusCheckMaxCount ]; then
		echo "---Cannot connect to the dashboard container---" | tee -a $LOGFILE 2>&1
		exit 1
	fi
	DashboardPodStatus=$(kubectl get pods --namespace kube-system | grep "kubernetes-dashboard" | awk 'NR == 1' | awk '{print $3}')
done
echo "---Check $StatusCheckCount: $DashboardPodStatus---" | tee -a $LOGFILE 2>&1

EOF
    destination = "/tmp/dashboard-installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/dashboard-installation.sh; bash /tmp/dashboard-installation.sh"
    ]
  }
}

##############################################################
# Install Strongloop Three Tiers
##############################################################
resource "null_resource" "install_strongloop_three_tiers"{
  depends_on    = ["null_resource.install_dashboard"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
	host        = "${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

LOGFILE="/var/log/install_kubernetes_strongloop_three_tiers.log"

Count=$1
DBUserPwd=$2

MYIP=$(hostname --ip-address)

# create a todolist-mongodb deployment
echo "---create a replication controller for todolist-mongodb---" | tee -a $LOGFILE 2>&1
cat << EOT > todolist-mongodb-deployment.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: todolist-mongodb-deployment
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: todolist-mongodb
    spec:
      containers:
      - name: todolist-mongodb
        image: mongo:3.4.0
EOT

kubectl create -f todolist-mongodb-deployment.yaml             >> $LOGFILE 2>&1 || { echo "---Failed to create todolist-mongo deployment---" | tee -a $LOGFILE; exit 1; }

echo "---create an user in mongodb---" | tee -a $LOGFILE 2>&1
MongoPodStatus=$(kubectl get pod | grep "todolist-mongodb-deployment" | awk '{print $3}')
StatusCheckMaxCount=120
StatusCheckCount=0
while [ "$MongoPodStatus" != "Running" ]; do
	echo "---Check $StatusCheckCount: $MongoPodStatus---" | tee -a $LOGFILE 2>&1
	sleep 10
	let StatusCheckCount=StatusCheckCount+1	
	if [ $StatusCheckCount -eq $StatusCheckMaxCount ]; then
		echo "---Cannot connect to the mongodb container---" | tee -a $LOGFILE 2>&1 
		exit 1
	fi
	MongoPodStatus=$(kubectl get pod | grep "todolist-mongodb-deployment" | awk '{print $3}') 
done

MongoPod=$(kubectl get pod | grep "todolist-mongodb-deployment" | awk '{print $1}')
kubectl exec $MongoPod -- bash -c 'echo "db.createUser({user:\"sampleUser\", pwd: \"'$DBUserPwd'\", roles: [{role: \"userAdminAnyDatabase\", db: \"admin\"}]})" > mongouser.js' >> $LOGFILE 2>&1 || { echo "---Failed to create file in the container---" | tee -a $LOGFILE; }
kubectl exec $MongoPod -- mongo localhost:27017/admin mongouser.js                                                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to add user---" | tee -a $LOGFILE; }

# define a service for the todolist-mongodb deployment
echo "---define a service for the todolist-mongodb---" | tee -a $LOGFILE 2>&1
cat << EOT > todolist-mongodb-service.yaml     
apiVersion: v1
kind: Service
metadata:
  name: todolist-mongodb-service
spec:
  externalIPs:
    - $MYIP
  ports:
    - port: 27017
  selector:
    app: todolist-mongodb
EOT

kubectl create -f todolist-mongodb-service.yaml               >> $LOGFILE 2>&1 || { echo "---Failed to create todolist-mongo service---" | tee -a $LOGFILE; exit 1; }

# create a todolist-strongloop deployment
echo "---create a replication controller for todolist-strongloop---" | tee -a $LOGFILE 2>&1
cat << EOT > todolist-strongloop-deployment.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: todolist-strongloop-deployment
spec:
  replicas: $Count
  template:
    metadata:
      labels:
        app: todolist-strongloop
    spec:
      containers:
      - name: todolist-strongloop
        image: centos:latest
        command: ["/bin/bash"]
        args: ["-c", "bash /tmp/installStrongloop.sh $MYIP $DBUserPwd;sleep infinity"]
        ports:
        - containerPort: 3000
        volumeMounts:
        - mountPath: /tmp
          name: temp-volume
      volumes:
      - name: temp-volume
        hostPath:
          path: /tmp        
EOT

kubectl create -f todolist-strongloop-deployment.yaml        >> $LOGFILE 2>&1 || { echo "---Failed to create todolist-strongloop deployment---" | tee -a $LOGFILE; exit 1; }

# define a service for the todolist-strongloop deployment
echo "---define a service for the todolist-strongloop---" | tee -a $LOGFILE 2>&1
cat << EOT > todolist-strongloop-service.yaml 
apiVersion: v1
kind: Service
metadata:
  name: todolist-strongloop-service
spec:
  externalIPs:
    - $MYIP
  ports:
    - port: 3000
  selector:
    app: todolist-strongloop
EOT

kubectl create -f todolist-strongloop-service.yaml          >> $LOGFILE 2>&1 || { echo "---Failed to create todolist-strongloop service---" | tee -a $LOGFILE; exit 1; }

# create a todolist-angularjs deployment
echo "---create a replication controller for todolist-angularjs---" | tee -a $LOGFILE 2>&1
cat << EOT > todolist-angularjs-deployment.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: todolist-angularjs-deployment
spec:
  replicas: $Count
  template:
    metadata:
      labels:
        app: todolist-angularjs
    spec:
      containers:
      - name: todolist-angularjs
        image: centos:latest
        command: ["/bin/bash"]
        args: ["-c", "bash /tmp/installAngularJs.sh $MYIP 8090;sleep infinity"]
        ports:
        - containerPort: 8090
        volumeMounts:
        - mountPath: /tmp
          name: temp-volume
      volumes:
      - name: temp-volume
        hostPath:
          path: /tmp          
EOT

kubectl create -f todolist-angularjs-deployment.yaml        >> $LOGFILE 2>&1 || { echo "---Failed to create todolist-angularjs deployment---" | tee -a $LOGFILE; exit 1; }

# define a service for the todolist-angularjs deployment
echo "---define a service for the todolist-angularjs---" | tee -a $LOGFILE 2>&1
cat << EOT > todolist-angularjs-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: todolist-angularjs-service
spec:
  externalIPs:
    - $MYIP
  ports:
    - port: 8090
  selector:
    app: todolist-angularjs
EOT

kubectl create -f todolist-angularjs-service.yaml          >> $LOGFILE 2>&1 || { echo "---Failed to create todolist-anngular service---" | tee -a $LOGFILE; exit 1; }

EOF
    destination = "/tmp/strongloop-three-tiers-installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/strongloop-three-tiers-installation.sh; bash /tmp/strongloop-three-tiers-installation.sh \"${var.count}\" \"${var.mongodb_user_password}\"",
      "reboot"
    ]
  }
}

##############################################################
# Check status
##############################################################
resource "null_resource" "check_strongloop_status"{
  depends_on    = ["null_resource.install_strongloop_three_tiers"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
	host        = "${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}"
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
      "chmod +x /tmp/checkStatus.sh; bash /tmp/checkStatus.sh http://\"${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}\":3000/explorer/"
    ]
  }
}

resource "null_resource" "check_angularjs_status"{
  depends_on    = ["null_resource.check_strongloop_status"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
	host        = "${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "bash /tmp/checkStatus.sh http://\"${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}\":8090",
      "sleep 60"
    ]
  }
}

#########################################################
# Output
#########################################################
output "Please access the kubernetes dashboard" {
    value = "http://${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}:8080/ui"
}

output "Please access the sample application" {
    value = "http://${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}:8090"
}

output "Please be aware that node's ip addresses" {
    value = ["${ibm_compute_vm_instance.kuberentes_node_vm.*.ipv4_address}"]
}
