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