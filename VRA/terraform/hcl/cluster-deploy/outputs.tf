output "vra7_deployment_single_vmware_node" {
  ###
  #You can get the individual IPs using the commented usage below
  #value       = element(vra7_deployment.single_vmware_node[0].resource_configuration[*].ip_address, 1)
  ###
  value       = vra7_deployment.single_vmware_node[0].resource_configuration[*].ip_address
  description = "Array of IP addresses of the deployed cluster nodes"
}

output "vra7_deployment_single_vmware_node_map" {
  ###
  #Map of resource name and ip
  ###
  value = {
    for resource in vra7_deployment.single_vmware_node[0].resource_configuration:
      resource.name => resource.ip_address
  }
  description = "Map of resource name and IP address of the deployed cluster nodes"
}