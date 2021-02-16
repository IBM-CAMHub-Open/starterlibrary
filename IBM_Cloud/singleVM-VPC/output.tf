# server Floating IP address
output "server_floating_ip_address" {
  value = ibm_is_floating_ip.cam_floatingip.address
}

# server private IP address
output "server_private_ip_address" {
  value = ibm_is_instance.cam-server.primary_network_interface[0].primary_ipv4_address
}
