output "cluster_ip" {
  value  = "${module.cluster.cluster_ip}"
}

output "cluster_name" {
  value = "${module.cluster.cluster_name}"
}

output "cluster_config" {
  value = "${module.cluster.cluster_config}"
}

output "cluster_certificate_authority" {
  value = "${module.cluster.cluster_certificate_authority}"
}