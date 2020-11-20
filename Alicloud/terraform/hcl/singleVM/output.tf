output "private_ip_address" {
  value = alicloud_instance.ecs_instance.private_ip
}

output "public_ip_address" {
  value = alicloud_instance.ecs_instance.public_ip
}