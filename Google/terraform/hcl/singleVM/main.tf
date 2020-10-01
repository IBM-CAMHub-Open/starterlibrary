// Google Cloud provider
provider "google" {
  version = "~> 1.5"
}

module "camtags" {
  source = "../Modules/camtags"
}

variable "unique_resource_name" {
  description = "A unique name for the resource, required by GCE."
}

variable "machine_type" {
  description = "The machine type to create."
  default = "n1-standard-1"
}

variable "boot_disk" {
  description = "The boot disk for the instance."
  default = "centos-cloud/centos-7"
}

variable "zone" {
  description = "The zone the resource should be created in."
  default = "us-central1-a"
}

variable "gce_ssh_user" {
  description = "A user name used to connect to the deployed VM in GCE."
}
variable "gce_ssh_public_key" {
  description = "Public key used to connect to the deployed VM in GCE."
}

// Create a new compute engine resource
resource "google_compute_instance" "default" {
  name         = "${var.unique_resource_name}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  boot_disk {
    initialize_params {
      image = "${var.boot_disk}"
    }
  }
  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
  metadata {
    ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_public_key}"
  }
  labels = "${module.camtags.tagsmap}"
}

output "Name" {
  value = "${google_compute_instance.default.name}"
}

output "External_IP" {
  value = "${google_compute_instance.default.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "Internal_IP" {
  value = "${google_compute_instance.default.network_interface.0.address}"
}
