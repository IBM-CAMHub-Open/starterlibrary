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
# Define the vsphere provider
#########################################################
provider "vsphere" {
  allow_unverified_ssl = true
}

#########################################################
# Define the variables
#########################################################
variable "kubernetes_master_name" {
    description = "Name of kubernetes master server; the names of managed nodes are the master name with count index"
    default     = "kubernetes-vm"
}

variable "count" {
    description = "Number of managed nodes"
    default     = 1
}

variable "folder" {
  description = "Target vSphere folder for Virtual Machine"
  default     = ""
}

variable "datacenter" {
  description = "Target vSphere datacenter for Virtual Machine creation"
  default     = ""
}

variable "master_server_vcpu" {
  description = "Number of Virtual CPU for the kubernetes master server; must not be less than 2 cores"
  default     = 2
}

variable "master_server_memory" {
  description = "Memory for the kubernetes master server in GBs; must not be less than 4GB"
  default     = 4
}

variable "node_server_vcpu" {
  description = "Number of Virtual CPU for the kubernetes node servers; must not be less than 2 cores"
  default     = 2
}

variable "node_server_memory" {
  description = "Memory for the kubernetes node servers in GBs; must not be less than 4GB"
  default     = 4
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

variable "master_ipv4_address" {
  description = "IPv4 address for vNIC configuration in kubernetes master"
}

variable "node_ipv4_addresses" {
  description = "IPv4 addresses for vNIC configuration in kubernetes nodes"
  type        = "list"
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

variable "master_server_vm_template" {
  description = "Source VM or Template label for cloning to kubernetes master server"
}

variable "master_server_ssh_user" {
  description = "The user for ssh connection to kubernetes master server, which is default in template"
  default     = "root"
}

variable "master_server_ssh_user_password" {
  description = "The user password for ssh connection to kubernetes master server, which is default in template"
}

variable "node_server_vm_template" {
  description = "Source VM or Template label for cloning to kubernetes node servers"
}

variable "node_server_ssh_user" {
  description = "The user for ssh connection to kubernetes node servers, which is default in template"
  default     = "root"
}

variable "node_server_ssh_user_password" {
  description = "The user password for ssh connection to kubernetes node servers, which is default in template"
}

#variable "camc_private_ssh_key" {
#  description = "The base64 encoded private key for ssh connection"
#}

variable "user_public_key" {
  description = "User-provided public SSH key used to connect to the virtual machine"
  default     = "None"
}

##############################################################
# Create Virtual Machine for Kubernetes Master
##############################################################
resource "vsphere_virtual_machine" "kubernetes_master_vm" {
  name         = "${var.kubernetes_master_name}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.master_server_vcpu}"
  memory       = "${var.master_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.master_ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.master_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.master_server_ssh_user}"
    password    = "${var.master_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${self.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\""
    ]
  }
}

##############################################################
# Create Virtual Machine for Kubernetes Nodes
##############################################################
resource "vsphere_virtual_machine" "kuberentes_node_vm" {
  count        = "${var.count}"
  name         = "${format("${var.kubernetes_master_name}-%d", count.index+1)}"
  folder       = "${var.folder}"
  datacenter   = "${var.datacenter}"
  vcpu         = "${var.node_server_vcpu}"
  memory       = "${var.node_server_memory * 1024}"
  cluster      = "${var.cluster}"
  dns_suffixes = "${var.dns_suffixes}"
  dns_servers  = "${var.dns_servers}"
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${element(var.node_ipv4_addresses,count.index)}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }

  disk {
    datastore = "${var.storage}"
    template  = "${var.node_server_vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.node_server_ssh_user}"
    password    = "${var.node_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${self.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/addkey.sh; bash /tmp/addkey.sh \"${var.user_public_key}\""
    ]
  }
}

##############################################################
# Install Kuberentes Master
##############################################################
resource "null_resource" "install_kubernetes_master"{

  # Specify the ssh connection
  connection {
    user        = "${var.master_server_ssh_user}"
    password    = "${var.master_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}"
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
LOCAL_IP=$(bypassIPChecker 127 0 0 1)
ATOM_NETWORK_IP=$(bypassIPChecker 172 17 0 0)
BIND_IP=$(bypassIPChecker 0 0 0 0)
CLUSTER_IP=$(bypassIPChecker 10 10 10 0)

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

# Set up hostname and obtain IP
echo "---start hostname, ip address setup---" | tee -a $LOGFILE 2>&1
retryInstall "yum install curl -y"                                    >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install bind-utils -y"                              >> $LOGFILE 2>&1 || { echo "---Failed to install bind-utils---" | tee -a $LOGFILE; exit 1; }

MYIP=$(hostname --ip-address)
echo "---master node ip address is $MYIP---" | tee -a $LOGFILE 2>&1

hostname $MYIP                                                        >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }
hostname | tee /etc/hostname                                          >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }
echo "---start installing kubernetes master node on $MYIP---" | tee -a $LOGFILE 2>&1

# install packages
systemctl disable firewalld                                           >> $LOGFILE 2>&1 || { echo "---Failed to disable firewall---" | tee -a $LOGFILE; exit 1; }
systemctl stop firewalld                                              >> $LOGFILE 2>&1 || { echo "---Failed to stop firewall---" | tee -a $LOGFILE; exit 1; }
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   >> $LOGFILE 2>&1 || { echo "---Failed to config selinux---" | tee -a $LOGFILE; exit 1; }
setenforce 0                                                          >> $LOGFILE 2>&1 || { echo "---Failed to set enforce---" | tee -a $LOGFILE; exit 1; }

# enable repo
retryInstall "yum install -y yum-utils"                               >> $LOGFILE 2>&1 || { echo "---Failed to install yum-config-manager---" | tee -a $LOGFILE; exit 1; }
yum-config-manager --enable rhel-7-server-extras-rpms                 >> $LOGFILE 2>&1 || { echo "---Failed to enable rhel-7-server-optional-rpms---" | tee -a $LOGFILE; exit 1; }

retryInstall "yum install etcd -y"                                    >> $LOGFILE 2>&1 || { echo "---Failed to install etcd---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install flannel -y"                                 >> $LOGFILE 2>&1 || { echo "---Failed to install flannel---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install kubernetes -y"                              >> $LOGFILE 2>&1 || { echo "---Failed to install kubernetes---" | tee -a $LOGFILE; exit 1; }

# configure etcd
echo "---start to write etcd config to /etc/etcd/etcd.conf---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/etcd/etcd.conf
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://$MYIP:2379,http://$LOCAL_IP:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://$MYIP:2379,http://$LOCAL_IP:2379"
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
KUBE_ETCD_SERVERS="--etcd-servers=http://$MYIP:2379"
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
KUBE_MASTER="--master=http://$MYIP:8080"
EOT

# configure flannel to use network defined and stored in etcd
echo "---start to write flannel config to /etc/sysconfig/flanneld---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://$MYIP:2379"
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

##############################################################
# Install Kuberentes Nodes
##############################################################
resource "null_resource" "install_kubernetes_node"{
  depends_on    = ["null_resource.install_kubernetes_master"]
  count         = "${var.count}"

  # Specify the ssh connection
  connection {
    user        = "${var.node_server_ssh_user}"
    password    = "${var.node_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${element(vsphere_virtual_machine.kuberentes_node_vm.*.network_interface.0.ipv4_address,count.index)}"
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

# Set up hostname and obtain IP
echo "---start hostname, ip address setup---" | tee -a $LOGFILE 2>&1
retryInstall "yum install curl -y"                                    >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install bind-utils -y"                              >> $LOGFILE 2>&1 || { echo "---Failed to install bind-utils---" | tee -a $LOGFILE; exit 1; }

MYIP=$(hostname --ip-address)
echo "---minion node ip address is $MYIP---" | tee -a $LOGFILE 2>&1

hostname $MYIP                                                        >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }
hostname | tee /etc/hostname                                          >> $LOGFILE 2>&1 || { echo "---Failed to set hostname---" | tee -a $LOGFILE; exit 1; }

echo "---start installing kubernetes minion node on $MYIP---" | tee -a $LOGFILE 2>&1

# install packages
systemctl disable firewalld                                           >> $LOGFILE 2>&1 || { echo "---Failed to disable firewall---" | tee -a $LOGFILE; exit 1; }
systemctl stop firewalld                                              >> $LOGFILE 2>&1 || { echo "---Failed to stop firewall---" | tee -a $LOGFILE; exit 1; }
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   >> $LOGFILE 2>&1 || { echo "---Failed to config selinux---" | tee -a $LOGFILE; exit 1; }
setenforce 0                                                          >> $LOGFILE 2>&1 || { echo "---Failed to set enforce---" | tee -a $LOGFILE; exit 1; }

# enable repo
retryInstall "yum install -y yum-utils"                               >> $LOGFILE 2>&1 || { echo "---Failed to install yum-config-manager---" | tee -a $LOGFILE; exit 1; }
yum-config-manager --enable rhel-7-server-extras-rpms                 >> $LOGFILE 2>&1 || { echo "---Failed to enable rhel-7-server-optional-rpms---" | tee -a $LOGFILE; exit 1; }

retryInstall "yum install flannel -y"                                 >> $LOGFILE 2>&1 || { echo "---Failed to install flannel---" | tee -a $LOGFILE; exit 1; }
retryInstall "yum install kubernetes -y"                              >> $LOGFILE 2>&1 || { echo "---Failed to install kubernetes---" | tee -a $LOGFILE; exit 1; }

# configure base kubernetes
echo "---start to write kubernetes config to /etc/kubernetes/config---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=http://$MASTERIP:8080"
EOT

# configure flannel to use network defined and stored in etcd
echo "---start to write flannel config to /etc/sysconfig/flanneld---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://$MASTERIP:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
EOT

# configure flannel to use network defined and stored in etcd
echo "---start to write kublet config to /etc/kubernetes/kubelet---" | tee -a $LOGFILE 2>&1
cat << EOT > /etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=$BIND_IP"
KUBELET_HOSTNAME="--hostname-override=$MYIP"
KUBELET_API_SERVER="--api-servers=http://$MASTERIP:8080"
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

if [ -n "$http_proxy" ] ; then
    echo "---enable http proxy for docker----" | tee -a $LOGFILE 2>&1

    DOCKER_HTTP_PROXY_FOLDER=/etc/systemd/system/docker.service.d
    mkdir $DOCKER_HTTP_PROXY_FOLDER
    touch $DOCKER_HTTP_PROXY_FOLDER/http-proxy.conf
    cat << EOT > $DOCKER_HTTP_PROXY_FOLDER/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$http_proxy/"
EOT
    systemctl daemon-reload                                        >> $LOGFILE 2>&1 || { echo "---Failed to reload docker daemon---" | tee -a $LOGFILE; exit 1; }
    systemctl restart docker                                       >> $LOGFILE 2>&1 || { echo "---Failed to restart docker---" | tee -a $LOGFILE; exit 1; }
fi

echo "---kubernetes minion node installed successfully---" | tee -a $LOGFILE 2>&1

EOF
    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}\""
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
    user        = "${var.master_server_ssh_user}"
    password    = "${var.master_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}"
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

curl -O https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml                                    >> $LOGFILE 2>&1 || { echo "---Failed to download kubernetes dashboard yaml---" | tee -a $LOGFILE; exit 1; }
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
# Install Nginx
##############################################################
resource "null_resource" "install_nginx"{
  depends_on    = ["null_resource.install_dashboard"]

  # Specify the ssh connection
  connection {
    user        = "${var.master_server_ssh_user}"
    password    = "${var.master_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_kubernetes_nginx.log"

# number of nginx
Count=$1

MYIP=$(hostname --ip-address)

# create an nginx deployment
echo "---create a replication controller for nginx---" | tee -a $LOGFILE 2>&1
cat << EOT > nginx-deployment.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: $Count
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
EOT

kubectl create -f nginx-deployment.yaml                       >> $LOGFILE 2>&1 || { echo "---Failed to create nginx deployment---" | tee -a $LOGFILE; exit 1; }

# define a service for the nginx deployment
echo "---define a service for the nginx rc---" | tee -a $LOGFILE 2>&1
cat << EOT > nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  externalIPs:
    - $MYIP
  ports:
    - port: 80
  selector:
    app: nginx
EOT

kubectl create -f nginx-service.yaml                         >> $LOGFILE 2>&1 || { echo "---Failed to create nginx service---" | tee -a $LOGFILE; exit 1; }

echo "---check nginx deployment status---" | tee -a $LOGFILE 2>&1

NginxPodStatus=$(kubectl get pod | grep "nginx-deployment" | awk 'NR == 1' | awk '{print $3}')
StatusCheckMaxCount=120
StatusCheckCount=0
while [ "$NginxPodStatus" != "Running" ]; do
	echo "---Check $StatusCheckCount: $NginxPodStatus---" | tee -a $LOGFILE 2>&1
	sleep 10
	let StatusCheckCount=StatusCheckCount+1
	if [ $StatusCheckCount -eq $StatusCheckMaxCount ]; then
		echo "---Cannot connect to the nginx container---" | tee -a $LOGFILE 2>&1
		exit 1
	fi
	NginxPodStatus=$(kubectl get pod | grep "nginx-deployment" | awk 'NR == 1' | awk '{print $3}')
done
echo "---Check $StatusCheckCount: $NginxPodStatus---" | tee -a $LOGFILE 2>&1

EOF
    destination = "/tmp/nginx-installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nginx-installation.sh; bash /tmp/nginx-installation.sh \"${var.count}\"",
      "reboot"
    ]
  }
}

##############################################################
# Check status
##############################################################
resource "null_resource" "check_status"{
  depends_on    = ["null_resource.install_nginx"]

  # Specify the ssh connection
  connection {
    user        = "${var.master_server_ssh_user}"
    password    = "${var.master_server_ssh_user_password}"
#    private_key = "${base64decode(var.camc_private_ssh_key)}"
	host        = "${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}"
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
      "chmod +x /tmp/checkStatus.sh; bash /tmp/checkStatus.sh http://\"${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}\":8080"
    ]
  }
}

#########################################################
# Output
#########################################################
output "Please access the kubernetes dashboard" {
    value = "http://${vsphere_virtual_machine.kubernetes_master_vm.network_interface.0.ipv4_address}:8080/ui"
}

output "Please be aware that node's ip addresses" {
    value = ["${vsphere_virtual_machine.kuberentes_node_vm.*.network_interface.0.ipv4_address}"]
}
