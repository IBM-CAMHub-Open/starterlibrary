output "cluster_ip" {
  value = "${data.ibm_container_cluster_worker.cluster_workers.public_ip}"
}

output "cluster_name" {
  value = "${data.ibm_container_cluster_config.cluster_config.cluster_name_id}"
}

output "cluster_config" {
  value = "${base64encode(file(data.ibm_container_cluster_config.cluster_config.config_file_path))}"
}

output "cluster_certificate_authority" {
  value = "${base64encode(file(lookup(data.external.certificate_authority_location.result, var.cluster_name)))}"
}