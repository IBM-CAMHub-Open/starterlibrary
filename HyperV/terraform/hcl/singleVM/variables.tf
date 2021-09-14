variable "instance_name"{
  description="Virtual machine name"
}

variable "generation"{
  description="Virtual machine generation"
  default = 2
}

variable "processor_count"{
  description="Virtual machine processor count"
  default = 1
}

variable "static_memory"{
  description="Use static memory"
  default = true
}

variable "memory_startup_bytes"{
  description="Virtual machine startup memory"
  default = 2147483648
}

variable "resource_pool_name"{
  description="Resource pool name"
  default = "Primordial"
}

variable "iso_path"{
    description="Virtual machine ISO path"
    default="C:\\Users\\Administrator\\Downloads\\en_windows_server_2019_updated_jun_2021_x64_dvd_a2a2f782.iso"
}

variable "controller_type"{
    default = "Scsi"
    description = "Drive controller type"
} 

variable network_adapter_name {
  description = "The name for the virtual network adapter."
  default = "Network Adaptor"
}

variable network_switch_name {
  description = "Network switch name"
  default = "Intel(R) 82574L Gigabit Network Connection - Virtual Switch"
}

variable instance_vhd_path{
  description = "VHD Path"
  default = "c:\\users\\public\\documents\\hyper-v\\virtual hard disks\\myvm.vhdx"
}

variable instance_vhd_size{    
  description = "VHD Size"
  default = 107374182400
}

variable wait_timeout {
  description = "The amount of time in seconds to wait for to obtain IP or to wait for desired VM state"
  default = "10"
}

variable hw_thread_count_per_core{
  description = "The number of virtual SMT threads exposed to the virtual machine."
  default = "1"
}