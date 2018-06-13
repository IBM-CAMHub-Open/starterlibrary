##############################################################################
# Outputs
##############################################################################
output "cluster_master_ip" {
  value = "${element(compact(concat(ibm_compute_bare_metal.masters.*.public_ipv4_address, ibm_compute_vm_instance.masters.*.ipv4_address, ibm_compute_vm_instance.masters-vlan.*.ipv4_address, ibm_compute_vm_instance.masters-image.*.ipv4_address, ibm_compute_vm_instance.masters-vlan-image.*.ipv4_address)),0)}"
}
output "symphony_dehost_ip" {
  value = "${join(" ", concat(ibm_compute_vm_instance.dehosts.*.ipv4_address, ibm_compute_vm_instance.dehosts-vlan.*.ipv4_address))}"
}
output "cluster_web_interface" {
  value = "https://${element(compact(concat(ibm_compute_bare_metal.masters.*.public_ipv4_address, ibm_compute_vm_instance.masters.*.ipv4_address, ibm_compute_vm_instance.masters-vlan.*.ipv4_address, ibm_compute_vm_instance.masters-image.*.ipv4_address, ibm_compute_vm_instance.masters-vlan-image.*.ipv4_address)),0)}:8443/platform"
}
