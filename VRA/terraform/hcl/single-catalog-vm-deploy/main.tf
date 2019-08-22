# Terraform template that will deploy a single node vRA catalog and execute a remote exec command.

terraform {
  required_version = "> 0.8.0"
}

# Terraform vRA provider
provider "vra7" {
}

# This resource represents a single vRA catalog item and includes the required input properties. 
resource "vra7_deployment" "single_vmware_node" {
  count = "1"
  wait_timeout = "${var.single_vmware_node_timeout}"
  catalog_item_name = "single_vmware_node"
  resource_configuration {
    vSphere__vCenter__Machine_1.memory = "512"
    vSphere__vCenter__Machine_1.cpu = "1"
    vSphere__vCenter__Machine_1.ip_address = ""   # Leave blank auto populated by terraform
  }    
}

# This resource creates a connection to the deployed vm and executes a remote exec echo command.
resource "null_resource" "vSphere__vCenter__Machine_1" {
  provisioner "remote-exec" {
     inline = [
        "echo vRA instance up! > /tmp/vra_hello.txt"
      ]
  }
  connection {
    user = "${var.vSphere__vCenter__Machine_1_user}"
    password = "${var.vSphere__vCenter__Machine_1_password}"
    host = "${vra7_deployment.single_vmware_node.resource_configuration.vSphere__vCenter__Machine_1.ip_address}"
  }    
}

