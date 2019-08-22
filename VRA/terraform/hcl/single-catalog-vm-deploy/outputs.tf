
output "vra7_deployment.single_vmware_node" {
  value = "${vra7_deployment.single_vmware_node.resource_configuration.vSphere__vCenter__Machine_1.ip_address}"
  description = "IP address of deployed node"
}

