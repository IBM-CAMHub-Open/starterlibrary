variable "instance_name" {
  description = "Virtual machine name"
}

variable "public_key" {
  description = "Public key string"
}

variable "host_name" {
  description = "Hostname of the virtual machine"
}

variable "cpu_count" {
  description = "CPU Count of the virtual machine"
  default = "1"
}

variable "memory" {
  description = "Virtual machine memory in GB"
   default = "2"
}

variable "internet_max_bandwidth_out"{
  default="0"
  description= "Maximum outgoing bandwidth to the public network, measured in Mbps (Mega bit per second)"
}