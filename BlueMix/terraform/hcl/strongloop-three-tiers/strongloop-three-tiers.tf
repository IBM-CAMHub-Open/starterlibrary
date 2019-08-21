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
# Define the ibmcloud provider
#########################################################
provider "ibm" {
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
variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "strongloop-server-hostname" {
  description = "Hostname of the virtual instance (with Strongloop and NodeJS installed) to be deployed"
  default     = "strongloop-vm"
}

variable "angular-server-hostname" {
  description = "Hostname of the virtual instance (with AngularJS and NodeJS installed) to be deployed"
  default     = "angularjs-vm"
}

variable "mongodb-server-hostname" {
  description = "Hostname of the virtual instance (with MongoDB installed) to be deployed"
  default     = "mongodb-vm"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guests"
}

variable "mongodb_user_password" {
  description = "The password of an user in mongodb for sample application"
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
# Create Virtual Machine and install MongoDB
##############################################################
resource "ibm_compute_vm_instance" "mongodb_vm" {
  hostname                 = "${var.mongodb-server-hostname}"
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
  tags                     = ["${module.camtags.tagslist}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
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
yum install -y mongodb-org                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install mongodb-org---" | tee -a $LOGFILE; exit 1; }
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

##############################################################
# Create Virtual Machine for Strongloop
##############################################################
resource "ibm_compute_vm_instance" "strongloop_vm" {
  hostname                 = "${var.strongloop-server-hostname}"
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
  tags                     = ["${module.camtags.tagslist}"]
}

##############################################################
# Create Virtual Machine for AngularJS
##############################################################
resource "ibm_compute_vm_instance" "angularjs_vm" {
  hostname                 = "${var.angular-server-hostname}"
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
  tags                     = ["${module.camtags.tagslist}"]
}

##############################################################
# Install Strongloop
##############################################################
resource "null_resource" "install_strongloop" {
  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${ibm_compute_vm_instance.strongloop_vm.ipv4_address}"
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

echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${ibm_compute_vm_instance.mongodb_vm.ipv4_address}\" \"${var.mongodb_user_password}\"",
    ]
  }
}

##############################################################
# Install AngularJs
##############################################################
resource "null_resource" "install_angularjs" {
  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${ibm_compute_vm_instance.angularjs_vm.ipv4_address}"
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
#yum install gcc ruby ruby-devel rubygems make -y                           >> $LOGFILE 2>&1 || { echo "---Failed to install ruby---" | tee -a $LOGFILE; exit 1; }
echo "---start installing ruby pre-reqs---" | tee -a $LOGFILE 2>&1
yum install curl gpg gcc gcc-c++ make patch autoconf automake bison libffi-devel libtool patch readline-devel sqlite-devel zlib-devel openssl-devel gdbm -y >> $LOGFILE 2>&1 || { echo "---Failed to install ruby pre-reqs---" | tee -a $LOGFILE; exit 1; }
echo "---Download, make and install ruby 2.2.10---" | tee -a $LOGFILE 2>&1
wget https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.10.tar.gz
tar -zxvf ruby-2.2.10.tar.gz
cd ruby-2.2.10
./configure																		   >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
make																			   >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
sudo make install																   >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---start installing compass---" | tee -a $LOGFILE 2>&1
gem install compass                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install compass---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing compass and angularjs---" | tee -a $LOGFILE 2>&1

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

echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1

EOF

    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${ibm_compute_vm_instance.strongloop_vm.ipv4_address}\"",
    ]
  }
}

#########################################################
# Output
#########################################################
output "db_server_ip_address" {
  value = "${ibm_compute_vm_instance.mongodb_vm.ipv4_address}"
}

output "strongloop_server_ip_address" {
  value = "${ibm_compute_vm_instance.strongloop_vm.ipv4_address}"
}

output "angularjs_server_ip_address" {
  value = "${ibm_compute_vm_instance.angularjs_vm.ipv4_address}"
}

output "application_url" {
  value = "http://${ibm_compute_vm_instance.angularjs_vm.ipv4_address}:8080"
}
