output "access_urls" {
  value = "${ibm_resource_key.resourceKey.credentials}"
}

output "service_instance_name" {
  value = "${ibm_resource_instance.service.name}"
}
/*
output "host" {
  value = "${ibm_service_key.resourceKey.credentials.host}"
}
output "port" {
  value = "${ibm_service_key.resourceKey.credentials.port}"
}
output "password" {
  value = "${ibm_service_key.resourceKey.credentials.password}"
}
output "url" {
  value = "${ibm_service_key.resourceKey.credentials.url}"
}
output "username" {
  value = "${ibm_service_key.resourceKey.credentials.username}"
}
*/