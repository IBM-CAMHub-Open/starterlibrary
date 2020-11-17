output "ip_address" {
  value = alicloud_instance.ecs_instance.public_ip
}