provider "hyperv" {
}

resource "hyperv_vhd" "instance_vhd" {
  path = format("%s%s.vhdx",var.instance_vhd_path,var.instance_name)
  size = var.instance_vhd_size
}

resource "hyperv_machine_instance" "an_instance" {
  name = var.instance_name
  generation = var.generation
  processor_count = var.processor_count
  static_memory = var.static_memory
  memory_startup_bytes = var.memory_startup_bytes
  wait_for_state_timeout = var.wait_timeout
  wait_for_ips_timeout = var.wait_timeout

  vm_processor {
    hw_thread_count_per_core = var.hw_thread_count_per_core
  }

  network_adaptors {
      name = format("%s %s", var.instance_name, var.network_adapter_name)
      switch_name = var.network_switch_name
      wait_for_ips = false
  }

  hard_disk_drives {
    controller_type = var.controller_type
    path = hyperv_vhd.instance_vhd.path
    controller_number = 0
    controller_location = 0
    resource_pool_name = var.resource_pool_name
  }

  dvd_drives {
    controller_number = 0
    controller_location = 1
    path = var.iso_path
    resource_pool_name = var.resource_pool_name
  }
}
