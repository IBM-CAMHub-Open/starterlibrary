#################################################################
# Terraform template that will poll Infrastructure Management for approval
#
# Version: 2.4
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2020.
#
#################################################################

#########################################################
# Define the variables
#########################################################
variable "url" {
    description = "URL to retrieve approval status"
}

variable "username" {
    description = "Username to connect to Infrastructure Management"
}

variable "password" {
    description = "Password to connect to Infrastructure Management"
}

variable "token" {
    description = "Bearer token to connect to Infrastructure Management"
}

variable "curl_option" {
    default = ""
    description = "Options for curl command used to retrieve status from Infrastructure Management e.g. --insecure"
}

variable "wait_time" {
    default = 5
    description = "Wait time in seconds i.e. time after which poll should again happen to retrieve the approval status"
}

#########################################################
# Create file to store script output
#########################################################
resource "local_file" "approval_status" {
    content   = ""
    filename  = "${path.module}/approval_status"
}

#########################################################
# Poll Infrastructure Management for approval status
#########################################################
resource "null_resource" "poll_endpoint" {
 provisioner "local-exec" {
    command = "/bin/bash poll_endpoint.sh $URL $USERNAME $PASSWORD $TOKEN $CURL_OPTIONS $WAIT_TIME $FILE"
    environment = {
      URL          = var.url
      USERNAME     = var.username != "" ? var.username : "DEFAULT_USERNAME"
      PASSWORD     = var.password != "" ? var.password : "DEFAULT_PASSWORD"
      TOKEN        = var.token != "" ? var.token : "DEFAULT_TOKEN"
      CURL_OPTIONS = var.curl_option
      WAIT_TIME    = var.wait_time
      FILE         = local_file.approval_status.filename
    }
  }
  depends_on = [
    local_file.approval_status
  ] 
}

#########################################################
# Data
#########################################################
data "local_file" "approval_status" {
    filename = local_file.approval_status.filename

    depends_on = [
    null_resource.poll_endpoint,
  ] 
}

#########################################################
# Output
#########################################################
output "approval_status" {
  value = data.local_file.approval_status.content

  depends_on = [
    null_resource.poll_endpoint,
  ] 
}
