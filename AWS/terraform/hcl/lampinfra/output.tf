#########################################################
# Output
#########################################################
output "webserver_ip_address" {
  value = "${aws_instance.web_server.public_ip}"
}

output "dbserver_ip_address" {
  value = "${aws_instance.db_server.public_ip}"
}
