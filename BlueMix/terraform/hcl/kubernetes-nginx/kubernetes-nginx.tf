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

MYIP=$(hostname --ip-address)
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

##############################################################
# Install Kuberentes Nodes
##############################################################
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

MYIP=$(hostname --ip-address)
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

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installation.sh; bash /tmp/installation.sh \"${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}\""
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
      "chmod +x /tmp/checkStatus.sh; bash /tmp/checkStatus.sh http://\"${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}\":8080"
    ]
  }
}

#########################################################
# Output
#########################################################
output "Please access the kubernetes dashboard" {
    value = "http://${ibm_compute_vm_instance.kubernetes_master_vm.ipv4_address}:8080/ui"
}

output "Please be aware that node's ip addresses" {
    value = ["${ibm_compute_vm_instance.kuberentes_node_vm.*.ipv4_address}"]
}
