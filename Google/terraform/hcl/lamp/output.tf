output "mariadb_ip" {
  value = google_compute_instance.mariadb.network_interface.0.access_config.0.nat_ip
}

output "php_ip" {
  value = google_compute_instance.php.network_interface.0.access_config.0.nat_ip
}

output "test_url" {
  value = "http://${google_compute_instance.php.network_interface.0.access_config.0.nat_ip}/test.php"
}

