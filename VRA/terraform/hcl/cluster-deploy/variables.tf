variable "single_vmware_node_timeout" {
  type        = string
  description = "Time to wait (in minutes) for a vRA deployment to complete successfully"
}

variable "vSphere__vCenter__Machine_1_user" {
  type        = string
  description = "Host username"
}

variable "vSphere__vCenter__Machine_1_password" {
  type        = string
  description = "Host password"
}

variable "single_vmware_node_cluster_size" {
  type        = string
  description = "Cluster size"
}