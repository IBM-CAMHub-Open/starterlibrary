provider "alicloud" {

}

module "camtags" {
  source = "../Modules/camtags"
}

data "alicloud_instance_types" "flavor" {
  cpu_core_count = var.cpu_count
  memory_size    = var.memory
}

data "alicloud_images" "ubuntu" {
  name_regex  = "^ubuntu"
  most_recent = true
  owners      = "system"
}

data "alicloud_zones" "camc_zones" {
}

resource "alicloud_vpc" "cam_vpc" {
  cidr_block = "10.1.0.0/21"
  name       = "${var.instance_name}-cam-vpc"
}

resource "alicloud_security_group" "cam_sg" {
  name        = "${var.instance_name}-cam-sg"
  vpc_id 	  = alicloud_vpc.cam_vpc.id
}

resource "alicloud_vswitch" "cam_vswitch" {
  vpc_id            = alicloud_vpc.cam_vpc.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = data.alicloud_zones.camc_zones.zones[0].id
  name              = "${var.instance_name}-cam-vswitch"
}

resource "alicloud_key_pair" "cam_publickey" {
  key_name   = "${var.instance_name}-cam-key"
  public_key = var.public_key
}

resource "alicloud_instance" "ecs_instance" {
  image_id             = "${data.alicloud_images.ubuntu.images.0.id}"
  instance_type        = "${data.alicloud_instance_types.flavor.instance_types.0.id}"
  security_groups      = ["${alicloud_security_group.cam_sg.id}"]
  instance_name        = var.host_name
  host_name            = var.host_name
  tags				   = "${module.camtags.tagsmap}"
  key_name			   = "${var.instance_name}-cam-key"
  vswitch_id           = alicloud_vswitch.cam_vswitch.id
}

