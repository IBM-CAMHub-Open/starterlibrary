output "access_urls" {
  value = "${ibm_service_key.serviceKey.credentials}"
}

output "service_instance_name" {
  value = "${ibm_service_instance.service.name}"
}
/*
output "host" {
  value = "${ibm_service_key.serviceKey.credentials.host}"
}
output "port" {
  value = "${ibm_service_key.serviceKey.credentials.port}"
}
output "password" {
  value = "${ibm_service_key.serviceKey.credentials.password}"
}
output "url" {
  value = "${ibm_service_key.serviceKey.credentials.url}"
}
output "username" {
  value = "${ibm_service_key.serviceKey.credentials.username}"
}
*/