#########################################################
# Output
#########################################################
output "webserver_ip_address" {
  value = "${aws_instance.php_server.public_ip}/test.php"
}

output "dbserver_ip_address" {
  value = "${aws_db_instance.mysql.address}"
}
