variable "instance_name" {
  description = "Virtual machine name"
}

variable "public_key" {
  description = "Public key string"
}

variable "host_name" {
  description = "Hostname of the virtual machine"
}

variable "cpu_core_count" {
  description = "CPU Count of the virtual machine"
  default = "1"
}

variable "memory_size" {
  description = "Virtual machine memory in GB"
  default = "2"
}

variable "internet_max_bandwidth_out"{
  default="0"
  description= "Maximum outgoing bandwidth to the public network, measured in Mbps (Mega bit per second)"
}

variable "image_type" {
  description = "A list of the image type to be queried."
  default = ["PUBLIC_IMAGE"]
  type = list(string)
}

variable "os_name" {
  description = "A string to apply with fuzzy match to the os_name attribute on the image list returned by TencentCloud."
  default = "centos"
}

variable "system_disk_type" {
  description = "Type of the system disk."
  default = "CLOUD_BASIC"
}

variable "system_disk_size" {
  description = "Size of the system disk. "
  default = "50"
}

variable "allocate_public_ip" {
  description = "Associate a public IP address with an virtual machine instance."
  default = "true"
}



