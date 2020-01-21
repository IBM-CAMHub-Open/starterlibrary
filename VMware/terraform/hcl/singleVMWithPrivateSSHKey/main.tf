provider "vsphere" {
  version              = "~> 1.3"
  allow_unverified_ssl = "true"
}
provider "tls" {
  version = "~> 1.0"
}

provider "random" {
  version = "~> 1.0"
}

locals{

  private_ssh_key         = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.vm_os_private_ssh_key)}"}"
  public_ssh_key          = "${length(var.vm_os_private_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.vm_os_public_ssh_key}"}"

	#private_ssh_key="${tls_private_key.generate.private_key_pem}"
	#public_ssh_key="${tls_private_key.generate.public_key_openssh}"
}

resource "random_string" "random-dir" {
  length  = 8
  special = false
}

resource "tls_private_key" "generate" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.vm_name}"
  folder           = "${var.vm_folder}"
  num_cpus         = "${var.vm_vcpu}"
  memory           = "${var.vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  guest_id         = "${data.vsphere_virtual_machine.vm_image_template.guest_id}"
  scsi_type        = "${data.vsphere_virtual_machine.vm_image_template.scsi_type}"

  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_image_template.id}"
    timeout = "${var.vm_clone_timeout}"
    customize {
      linux_options {
        domain    = "${var.vm_domain_name}"
        host_name = "${var.vm_name}"
      }

      network_interface {
        ipv4_address = "${var.vm_ipv4_address}"
        ipv4_netmask = "${var.vm_ipv4_netmask}"
      }

      ipv4_gateway    = "${var.vm_ipv4_gateway}"
      dns_suffix_list = "${var.dns_suffixes}"
      dns_server_list = "${var.dns_servers}"
    }
  }

  network_interface {
    network_id   = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.adapter_type}"
  }

  disk {
    label          = "${var.vm_name}.vmdk"
    size           = "${var.vm_disk_size}"
    keep_on_remove = "${var.vm_disk_keep_on_remove}"
    datastore_id   = "${data.vsphere_datastore.datastore.id}"
  }

  lifecycle {
    ignore_changes = [
      "datastore_id",
      "disk.0.datastore_id"
    ]
    create_before_destroy = true
  }

  # Specify the connection
  connection {
    type     = "ssh"
    user     = "${var.vm_os_user}"
    password = "${var.vm_os_password}"
    private_key = "${var.vm_os_private_ssh_key}"
    timeout = "30m"
  }

  provisioner "file" {
    destination = "VM_add_ssh_key.sh"

    content = <<EOF
# =================================================================
# Licensed Materials - Property of IBM
# 5737-E67
# @ Copyright IBM Corporation 2016, 2017 All Rights Reserved
# US Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
#!/bin/bash

if (( $# != 3 )); then
echo "usage: arg 1 is user, arg 2 is public key, arg3 is Private Key"
exit -1
fi

userid="$1"
ssh_key="$2"
private_ssh_key="$3"


echo "Userid: $userid"

echo "ssh_key: $ssh_key"
echo "private_ssh_key: $private_ssh_key"


user_home=$(eval echo "~$userid")
user_auth_key_file=$user_home/.ssh/authorized_keys
user_auth_key_file_private=$user_home/.ssh/id_rsa
user_auth_key_file_private_temp=$user_home/.ssh/id_rsa_temp
echo "$user_auth_key_file"
if ! [ -f $user_auth_key_file ]; then
echo "$user_auth_key_file does not exist on this system, creating."
mkdir -p $user_home/.ssh
chmod 700 $user_home/.ssh
touch $user_home/.ssh/authorized_keys
chmod 600 $user_home/.ssh/authorized_keys
else
echo "user_home : $user_home"
fi

echo "$user_auth_key_file"
echo "$ssh_key" >> "$user_auth_key_file"
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file"
exit -1
else
echo "updated $user_auth_key_file"
fi

# echo $private_ssh_key  >> $user_auth_key_file_private_temp
# decrypt=`cat $user_auth_key_file_private_temp | base64 --decode`
# echo "$decrypt" >> "$user_auth_key_file_private"

echo "$private_ssh_key"  >> "$user_auth_key_file_private"
chmod 600 $user_auth_key_file_private
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file_private"
exit -1
else
echo "updated $user_auth_key_file_private"
fi
rm -rf $user_auth_key_file_private_temp

EOF
  }
}

resource "null_resource" "add_ssh_key" {
  depends_on = ["vsphere_virtual_machine.vm"]
  # Specify the connection
  connection {
    type     = "ssh"
    user     = "${var.vm_os_user}"
    password = "${var.vm_os_password}"
    private_key = "${var.vm_os_private_ssh_key}"
    timeout = "30m"
    host     = "${var.vm_ipv4_address}"
  }
  
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "bash -c 'chmod +x VM_add_ssh_key.sh'",
      "bash -c './VM_add_ssh_key.sh  \"${var.vm_os_user}\" \"${local.public_ssh_key}\" \"${local.private_ssh_key}\">> VM_add_ssh_key.log 2>&1'",
    ]
  }
}
