provider "tencentcloud" {
  version    = "~> 1.39.0"
}

module "camtags" {
  source = "../Modules/camtags"
}

# Get availability zones
data "tencentcloud_availability_zones" "default" {
}

# Get availability images
data "tencentcloud_images" "default" {
  image_type = var.image_type
  os_name    = var.os_name
}

# Get availability instance types
data "tencentcloud_instance_types" "default" {
  cpu_core_count = var.cpu_core_count
  memory_size    = var.memory_size
}

resource "tencentcloud_key_pair" "cam_key" {
  key_name   = "${var.instance_name}_cam_key"
  public_key = var.public_key
}

# Create a web server
resource "tencentcloud_instance" "cam_instance" {
  instance_name              = var.instance_name
  availability_zone          = data.tencentcloud_availability_zones.default.zones.0.name
  image_id                   = data.tencentcloud_images.default.images.0.image_id
  instance_type              = data.tencentcloud_instance_types.default.instance_types.0.instance_type
  system_disk_type           = var.system_disk_type
  system_disk_size           = tonumber(var.system_disk_size)
  allocate_public_ip         = var.allocate_public_ip
  internet_max_bandwidth_out = var.internet_max_bandwidth_out
  security_groups            = [tencentcloud_security_group.cam_sg.id]
  hostname                   = var.host_name
  key_name                   = tencentcloud_key_pair.cam_key.id
}

# Create security group
resource "tencentcloud_security_group" "cam_sg" {
  name        = "cam sg"
  description = "cam security group for ssh"
}

# Create security group rule allow ssh request
resource "tencentcloud_security_group_rule" "cam_ssh" {
  security_group_id = tencentcloud_security_group.cam_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "22"
  policy            = "accept"
}