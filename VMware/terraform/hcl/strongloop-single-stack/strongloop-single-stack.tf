# This is a terraform generated template generated from final

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
  version              = "~> 1.3"
}

##############################################################
# Define pattern variables
##############################################################
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "strongloop_vm_datacenter" {
  name = var.strongloop_vm_datacenter
}

data "vsphere_datastore" "strongloop_vm_datastore" {
  name          = var.strongloop_vm_root_disk_datastore
  datacenter_id = data.vsphere_datacenter.strongloop_vm_datacenter.id
}

data "vsphere_resource_pool" "strongloop_vm_resource_pool" {
  name          = var.strongloop_vm_resource_pool
  datacenter_id = data.vsphere_datacenter.strongloop_vm_datacenter.id
}

data "vsphere_network" "strongloop_vm_network" {
  name          = var.strongloop_vm_network_interface_label
  datacenter_id = data.vsphere_datacenter.strongloop_vm_datacenter.id
}

data "vsphere_virtual_machine" "strongloop_vm_template" {
  name          = var.strongloop_vm_image
  datacenter_id = data.vsphere_datacenter.strongloop_vm_datacenter.id
}

##### Image Parameters variables #####

#Variable : strongloop_vm_name
variable "strongloop_vm_name" {
  type        = string
  description = "Generated"
  default     = "strongloop Vm"
}

#########################################################
##### Resource : strongloop_vm
#########################################################
variable "ssh_user" {
  description = "The user for ssh connection, which is default in template"
  default     = "root"
}

variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
}

variable "strongloop_vm_folder" {
  description = "Target vSphere folder for virtual machine"
}

variable "strongloop_vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "strongloop_vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "strongloop_vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default     = "1"
}

variable "strongloop_vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "1024"
}

variable "strongloop_vm_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
}

variable "strongloop_vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "strongloop_vm_dns_suffixes" {
  type        = list(string)
  description = "Name resolution suffixes for the virtual network adapter"
}

variable "strongloop_vm_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
}

variable "strongloop_vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "strongloop_vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "strongloop_vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "strongloop_vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "strongloop_vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "strongloop_vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "strongloop_vm_root_disk_type" {
  type        = string
  description = "Type of template disk volume"
  default     = "eager_zeroed"
}

variable "strongloop_vm_root_disk_controller_type" {
  type        = string
  description = "Type of template disk controller"
  default     = "scsi"
}

variable "strongloop_vm_root_disk_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "strongloop_vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default     = "25"
}

variable "strongloop_vm_image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

module "provision_proxy_strongloop_vm" {
  source              = "git::https://github.com/IBM-CAMHub-Open/terraform-modules.git//vmware/proxy?ref=1.0"
  ip                  = var.strongloop_vm_ipv4_address
  id                  = vsphere_virtual_machine.strongloop_vm.id
  ssh_user            = var.ssh_user
  ssh_password        = var.ssh_user_password
  http_proxy_host     = var.http_proxy_host
  http_proxy_user     = var.http_proxy_user
  http_proxy_password = var.http_proxy_password
  http_proxy_port     = var.http_proxy_port
  enable              = length(var.http_proxy_host) > 0 ? "true" : "false"
}

# vsphere vm
resource "vsphere_virtual_machine" "strongloop_vm" {
  name             = var.strongloop_vm_name
  folder           = var.strongloop_vm_folder
  num_cpus         = var.strongloop_vm_number_of_vcpu
  memory           = var.strongloop_vm_memory
  resource_pool_id = data.vsphere_resource_pool.strongloop_vm_resource_pool.id
  datastore_id     = data.vsphere_datastore.strongloop_vm_datastore.id
  guest_id         = data.vsphere_virtual_machine.strongloop_vm_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.strongloop_vm_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.strongloop_vm_template.id

    customize {
      linux_options {
        domain    = var.strongloop_vm_domain
        host_name = var.strongloop_vm_name
      }

      network_interface {
        ipv4_address = var.strongloop_vm_ipv4_address
        ipv4_netmask = var.strongloop_vm_ipv4_prefix_length
      }

      ipv4_gateway    = var.strongloop_vm_ipv4_gateway
      dns_suffix_list = var.strongloop_vm_dns_suffixes
      dns_server_list = var.strongloop_vm_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.strongloop_vm_network.id
    adapter_type = var.strongloop_vm_adapter_type
  }

  disk {
    label          = "${var.strongloop_vm_name}0.vmdk"
    size           = var.strongloop_vm_root_disk_size
    keep_on_remove = var.strongloop_vm_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.strongloop_vm_datastore.id
  }
}

resource "null_resource" "strongloop_vm_install_strongloop" {
  depends_on = [
    vsphere_virtual_machine.strongloop_vm,
    module.provision_proxy_strongloop_vm,
  ]

  connection {
    type                = "ssh"
    user                = var.ssh_user
    password            = var.ssh_user_password
    host                = vsphere_virtual_machine.strongloop_vm.clone[0].customize[0].network_interface[0].ipv4_address
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  provisioner "file" {
    content = <<EOF
    #!/bin/bash
    set -o errexit
set -o nounset
set -o pipefail
LOGFILE="/var/log/install_mongodb_strongloop_angular_strongloop.log"
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
MONGO_REPO=/etc/yum.repos.d/mongodb-org-3.4.repo
cat <<EOT | tee -a $MONGO_REPO                                                     >> $LOGFILE 2>&1 || { echo "---Failed to create mongo repo---" | tee -a $LOGFILE; exit 1; }
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOT
retryInstall "yum install -y mongodb-org"                                          >> $LOGFILE 2>&1 || { echo "---Failed to install mongodb-org---" | tee -a $LOGFILE; exit 1; }
service mongod start                                                               >> $LOGFILE 2>&1 || { echo "---Failed to start mongodb---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing mongodb---" | tee -a $LOGFILE 2>&1
#install node.js
echo "---start installing node.js---" | tee -a $LOGFILE 2>&1
retryInstall "yum install gcc-c++ make -y"                                         >> $LOGFILE 2>&1 || { echo "---Failed to install build tools---" | tee -a $LOGFILE; exit 1; }
curl -sL https://rpm.nodesource.com/setup_7.x | bash -                             >> $LOGFILE 2>&1 || { echo "---Failed to install the NodeSource Node.js 7.x repo---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install nodejs -y"                                               >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1
set +o nounset
if [[ -z "$${http_proxy}" ]]; then
  echo "No http proxy to set"
else
	echo "Set http proxy"
  npm config set proxy $${http_proxy}
fi
if [[ -z "$${https_proxy}" ]]; then
  echo "No https proxy to set"
else
	echo "Set https proxy"
  npm config set https-proxy $${https_proxy}
fi
set -o nounset
#install angularjs
echo "---start installing angularjs---" | tee -a $LOGFILE 2>&1
npm install -g grunt-cli bower yo generator-karma generator-angular                >> $LOGFILE 2>&1 || { echo "---Failed to install angular tools---" | tee -a $LOGFILE; exit 1; }
# enable repo to install ruby-devel
retryInstall "yum install -y yum-utils"                                            >> $LOGFILE 2>&1 || { echo "---Failed to install yum-config-manager---" | tee -a $LOGFILE; exit 1; }
yum-config-manager --enable rhel-7-server-optional-rpms                            >> $LOGFILE 2>&1 || { echo "---Failed to enable rhel-7-server-optional-rpms---" | tee -a $LOGFILE; exit 1; }
#retryInstall "yum install gcc ruby ruby-devel rubygems -y"                         >> $LOGFILE 2>&1 || { echo "---Failed to install ruby---" | tee -a $LOGFILE; exit 1; }
yum groupinstall 'Development Tools' -y                                            >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
echo "---start installing ruby pre-reqs---" | tee -a $LOGFILE 2>&1
yum install curl wget gpg gcc gcc-c++ make patch autoconf automake bison libffi-devel libtool patch readline-devel sqlite-devel zlib-devel openssl-devel gdbm -y >> $LOGFILE 2>&1 || { echo "---Failed to install ruby pre-reqs---" | tee -a $LOGFILE; exit 1; }
echo "---Download, make and install ruby 2.7.1---" | tee -a $LOGFILE 2>&1
wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.1.tar.gz
echo "---untar ruby 2.7.0---" | tee -a $LOGFILE 2>&1
tar -zxvf ruby-2.7.1.tar.gz
cd ruby-2.7.1
echo "---configire ruby 2.7.0---" | tee -a $LOGFILE 2>&1
./configure >> $LOGFILE 2>&1 
if [ $? -ne 0 ]; then
    echo "---Failed to configure ruby---"| tee -a $LOGFILE
    exit 1
fi
echo "---make ruby 2.7.0---" | tee -a $LOGFILE 2>&1
make >> $LOGFILE 2>&1 
if [ $? -ne 0 ]; then
    echo "---Failed to configure ruby---"| tee -a $LOGFILE
    exit 1
fi
echo "---make install ruby 2.7.0---" | tee -a $LOGFILE 2>&1
make install >> $LOGFILE 2>&1 
if [ $? -ne 0 ]; then
    echo "---Failed to configure ruby---"| tee -a $LOGFILE
    exit 1
fi
echo "---start installing compass---" | tee -a $LOGFILE 2>&1
gem install -V compass >> $LOGFILE 2>&1                                                               
if [ $? -ne 0 ]; then
    echo "---Failed to configure ruby---"| tee -a $LOGFILE
    exit 1
fi
echo "---finish installing compass and angularjs---" | tee -a $LOGFILE 2>&1
#install strongloop
echo "---start installing strongloop---" | tee -a $LOGFILE 2>&1
npm install -g strongloop                                                          >> $LOGFILE 2>&1 || { echo "---Failed to install strongloop---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing strongloop---" | tee -a $LOGFILE 2>&1
#install sample application
echo "---start installing sample application---" | tee -a $LOGFILE 2>&1
#create mongodb user
dbUserPwd=$(date | md5sum | head -c 10)
mongo admin --eval "db.createUser({user: \"sampleUser\", pwd: \"$dbUserPwd\", roles: [{role: \"userAdminAnyDatabase\", db: \"admin\"}]})"    >> $LOGFILE 2>&1 || { echo "---Failed to create MongoDB user---" | tee -a $LOGFILE; exit 1; }
PROJECT_NAME=sample
SAMPLE_DIR=$HOME/$PROJECT_NAME
retryInstall "yum install expect -y"                                                                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install Expect---" | tee -a $LOGFILE; exit 1; }
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
chmod 755 $SCRIPT_CREATE_PROJECT                                                                                                            >> $LOGFILE 2>&1 || { echo "---Failed to change permission of script---" | tee -a $LOGFILE; exit 1; }
./$SCRIPT_CREATE_PROJECT                                                                                                                    >> $LOGFILE 2>&1 || { echo "---Failed to execute script---" | tee -a $LOGFILE; exit 1; }
rm -f $SCRIPT_CREATE_PROJECT                                                                                                                >> $LOGFILE 2>&1 || { echo "---Failed to remove script---" | tee -a $LOGFILE; exit 1; }
#add dependency package
cd $SAMPLE_DIR
sed -i -e '/loopback-datasource-juggler/a\ \ \ \ "loopback-connector-mongodb": "^1.18.0",' package.json                                     >> $LOGFILE 2>&1 || { echo "---Failed to add dependency for loopback-connector-mongo---" | tee -a $LOGFILE; exit 1; }
#install packages in server side
npm install                                                                                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to install packages via npm---" | tee -a $LOGFILE; exit 1; }
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
chmod 755 $SCRIPT_CREATE_MODEL                                                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to change permission of script---" | tee -a $LOGFILE; exit 1; }
./$SCRIPT_CREATE_MODEL                                                                                                                      >> $LOGFILE 2>&1 || { echo "---Failed to execute script---" | tee -a $LOGFILE; exit 1; }
rm -f $SCRIPT_CREATE_MODEL                                                                                                                  >> $LOGFILE 2>&1 || { echo "---Failed to remove script---" | tee -a $LOGFILE; exit 1; }
#update server config
DATA_SOURCE_FILE=server/datasources.json
sed -i -e 's/\ \ }/\ \ },/g' $DATA_SOURCE_FILE                                                                                              >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e '/\ \ },/a\ \ "myMongoDB": {\n\ \ \ \ "host": "localhost",\n\ \ \ \ "port": 27017,\n\ \ \ \ "url": "mongodb://sampleUser:sampleUserPwd@localhost:27017/admin",\n\ \ \ \ "database": "Todos",\n\ \ \ \ "password": "sampleUserPwd",\n\ \ \ \ "name": "myMongoDB",\n\ \ \ \ "user": "sampleUser",\n\ \ \ \ "connector": "mongodb"\n\ \ }' $DATA_SOURCE_FILE    >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e "s/sampleUserPwd/$dbUserPwd/g" $DATA_SOURCE_FILE                                                                                  >> $LOGFILE 2>&1 || { echo "---Failed to update datasource.json---" | tee -a $LOGFILE; exit 1; }
MODEL_CONFIG_FILE=server/model-config.json
sed -i -e '/Todos/{n;d}' $MODEL_CONFIG_FILE                                                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to update model-config.json---" | tee -a $LOGFILE; exit 1; }
sed -i -e '/Todos/a\ \ \ \ "dataSource": "myMongoDB",' $MODEL_CONFIG_FILE                                                                   >> $LOGFILE 2>&1 || { echo "---Failed to update model-config.json---" | tee -a $LOGFILE; exit 1; }
SERVER_JS_FILE=server/server.js
sed -i -e "/app = module.exports = loopback()/a var path = require('path');\napp.use(loopback.static(path.resolve(__dirname, \'../client\')));" $SERVER_JS_FILE     >> $LOGFILE 2>&1 || { echo "---Failed to update server.js---" | tee -a $LOGFILE; exit 1; }
#install packages in client side
BOWERRC_FILE=.bowerrc
cat << EOT > $BOWERRC_FILE
{
  "directory": "client/vendor"
}
EOT
bower install jquery angular angular-resource angular-ui-router bootstrap --allow-root                                                             >> $LOGFILE 2>&1 || { echo "---Failed to install packages via bower---" | tee -a $LOGFILE; exit 1; }
#add client files
INDEX_HTML=client/index.html
cat << EOT > $INDEX_HTML
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Strongloop Angular Mongo Example</title>
    <link href="vendor/bootstrap/dist/css/bootstrap.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
  </head>
  <body ng-app="app">
    <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="#">Strongloop Angular Mongo Example</a>
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
    <script src="js/services/lb-services.js"></script>
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
'use strict';
angular
 .module('app', [
   'lbServices',
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
'use strict';
angular
 .module('app')
 .controller('TodoCtrl', ['\$scope', '\$state', 'Todos', function(\$scope,
     \$state, Todos) {
   \$scope.todos = [];
   function getTodos() {
     Todos
       .find()
       .\$promise
       .then(function(results) {
         \$scope.todos = results;
       });
   }
   getTodos();
   \$scope.addTodo = function() {
     Todos
       .create(\$scope.newTodo)
       .\$promise
       .then(function(todo) {
         \$scope.newTodo.content = '';
         \$scope.todoForm.content.\$setPristine();
         \$scope.todoForm.content.\$setUntouched();
         \$scope.todoForm.\$setPristine();
         \$scope.todoForm.\$setUntouched();
         \$('.focus').focus(); //JQuery hack for refocusing text input
         getTodos();
       });
   };
   \$scope.removeTodo = function(item) {
     Todos
       .deleteById(item)
       .\$promise
       .then(function() {
         getTodos();
       });
   };
 }]);
EOT
mkdir -p client/js/services
LB_SERVICE_JS_FILE=client/js/services/lb-services.js
lb-ng $SERVER_JS_FILE $LB_SERVICE_JS_FILE                                                                                                    >> $LOGFILE 2>&1 || { echo "---Failed to create lb-service.js---" | tee -a $LOGFILE; exit 1; }
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
SyslogIdentifier=strongloop-example
Environment=NODE_ENV=production PORT=3000
[Install]
WantedBy=multi-user.target
EOT
systemctl enable nodeserver.service                                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
systemctl start nodeserver.service                                                                                                          >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }
#update firewall
iptables -I INPUT 1 -p tcp -m tcp --dport 3000 -m conntrack --ctstate NEW -j ACCEPT                                                         >> $LOGFILE 2>&1 || { echo "---Failed to update firewall---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1

EOF


    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh",
    ]
  }
}

#########################################################
# Output
#########################################################
output "application_url" {
  value = "http://${vsphere_virtual_machine.strongloop_vm.clone[0].customize[0].network_interface[0].ipv4_address}:3000"
}

