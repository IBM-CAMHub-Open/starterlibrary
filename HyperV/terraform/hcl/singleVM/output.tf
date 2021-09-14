output "ip_address" {
  value = flatten(hyperv_machine_instance.an_instance.network_adaptors[*].ip_addresses)
}