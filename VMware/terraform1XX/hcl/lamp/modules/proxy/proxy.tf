##############################
#HTTP Proxy variables
##############################
variable "http_proxy_host" {
  type = string
  description = "HTTP proxy host URL with protocol. Example http://<ip_address>"
}

variable "http_proxy_user" {
  type = string
  description = "HTTP proxy user"
}

variable "http_proxy_port" {
  type = string
  description = "HTTP proxy port"
}

variable "http_proxy_password" {
  type = string
  description = "HTTP proxy password" 
}

##############################
#Connection Variables
##############################
variable "ssh_user" {
  description = "The user for ssh connection"
  default     = "root"
}

variable "ssh_password" {
  description = "The password for ssh connection"
}

variable "ip" {
  description = "The host ip"
}

variable "id" {
  description = "VM ID. Used for depends."  
}

##############################
#Variable to control enablement of this resource.
##############################

variable "enable" {
  description = "true to enable false otherwise."
  default = "false"
}

resource "null_resource" "proxy" {
  
  count = "${var.enable == "true" ? 1 : 0}"
  
  # Specify the connection
  connection {
    host                = "${var.ip}"
    type                = "ssh"
    user                = "${var.ssh_user}"
    password            = "${var.ssh_password}"
  }
  
  provisioner "file" {
    source      = "${path.module}/scripts/setproxy.sh"
    destination = "/tmp/setproxy.sh"
  }  

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "bash -c 'chmod +x /tmp/setproxy.sh'",
      "bash -c '/tmp/setproxy.sh \"${var.http_proxy_host}\" \"${var.http_proxy_user}\" \"${var.http_proxy_password}\" \"${var.http_proxy_port}\">> setproxy.log 2>&1'",
    ]
  }
}
