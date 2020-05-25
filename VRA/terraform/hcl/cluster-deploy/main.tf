# Terraform template that will deploy a single node vRA catalog and execute a remote exec command.

terraform {
  required_version = ">= 0.12"
}

# Terraform vRA provider
provider "vra7" { 
  version = ">= 1.0.1"  
}

# This resource represents a single vRA catalog item and includes the required input properties.
resource "vra7_deployment" "single_vmware_node" {
  count             = 1
  wait_timeout      = var.single_vmware_node_timeout
  catalog_item_name = "bhadrim-vmware-test"
  resource_configuration {
    cluster = var.single_vmware_node_cluster_size
    component_name = "vSphere__vCenter__Machine_1"
    configuration = {
      memory = 512
      cpu = 1
    }
  }
}

# This resource creates a connection to the deployed vm and executes a remote exec echo command.
resource "null_resource" "vSphere__vCenter__Machine_1" {
  count = var.single_vmware_node_cluster_size
  provisioner "remote-exec" {
    inline = [
      "echo vRA instance up! > /tmp/vra_hello.txt",
    ]
  }
  connection {
    user     = var.vSphere__vCenter__Machine_1_user
    password = var.vSphere__vCenter__Machine_1_password
    host     = element(vra7_deployment.single_vmware_node[0].resource_configuration[*].ip_address, count.index)
  }
}
