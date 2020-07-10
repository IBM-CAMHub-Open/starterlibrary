#################################################################
# Terraform template that will poll Cloudform for approval
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
# Define the Terraform version
#########################################################
terraform {
  required_version = "~> 0.12.0"
}

#########################################################
# Define the variables
#########################################################
variable "url" {
    description = "URL to retrieve approval status"
}

variable "username" {
    description = "Username to connect to CloudForms"
}

variable "password" {
    description = "Password to connect to CloudForms"
}

variable "curl_option" {
    description = "Options for curl command used to retrieve status from CloudForms e.g. --insecure"
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
# Poll Cloudform for approval status
#########################################################
resource "null_resource" "poll_endpoint" {
 provisioner "local-exec" {
    command = "/bin/bash poll_endpoint.sh $URL $USERNAME $PASSWORD $CURL_OPTIONS $WAIT_TIME $FILE"
    environment = {
      URL          = var.url
      USERNAME     = var.username
      PASSWORD     = var.password
      CURL_OPTIONS = var.curl_option
      WAIT_TIME    = var.wait_time
      FILE         = "${path.module}/approval_status"
    }
  }
  depends_on = [
    local_file.approval_status
  ] 
}

#########################################################
# Output
#########################################################
output "approval_status" {
  value = "${fileexists("${local_file.approval_status.filename}") ? file("${local_file.approval_status.filename}") : ""}"
  depends_on = [
    null_resource.poll_endpoint
  ] 
}