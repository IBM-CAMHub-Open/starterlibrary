variable "mariadb_hostname" {
  description = "A unique name for the MariaDB VM, required by GCE."
}

variable "mariadb_user" {
  description = "User to be added into db and sshed into servers"
  default     = "camuser"
}

variable "mariadb_pwd" {
  description = "User password for cam user; It should be alphanumeric with length in [8,16]"
}

variable "php_hostname" {
  description = "A unique name for the PHP VM, required by GCE."
}

variable "gce_ssh_user" {
  description = "A user name used to connect to the deployed VM in GCE."
}

variable "gce_ssh_public_key" {
  description = "Public key used to connect to the deployed VM in GCE."
}

variable "gce_ssh_private_key" {
  description = "Private key used to connect to the deployed VM in GCE."
}

variable "boot_disk" {
  description = "The boot disk for the instance."
  default = "centos-cloud/centos-7"
}

variable "zone" {
  description = "The zone the resource should be created in."
  default = "us-central1-a"
}

variable "machine_type" {
  description = "The machine type to create."
  default = "n1-standard-1"
}