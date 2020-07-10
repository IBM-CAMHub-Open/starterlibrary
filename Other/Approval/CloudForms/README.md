# Poll CloudForms for Approval

## Overview
Template polls CloudForms at certain interval to get the approval status of service. Polling stops once service status received is either `approved` or `denied` i.e. other than `pending_approval`. A template uses [Null Resource](https://www.terraform.io/docs/provisioners/null_resource.html) and [Local Exec Provisioner](https://www.terraform.io/docs/provisioners/local-exec.html) for polling.

More details on Managed services can be found [here](https://www.ibm.com/support/knowledgecenter/SSFC4F/product_welcome_cloud_pak.html).

## Deploying the template from Managed services

### Prerequisites

- Navigate to `Manage` -> `Shared parameters` -> `Create data type` -> Enter Name as `CloudForms Authentication Details`, Data type as `cf_auth_details` and Description as `Authentication details such as username and password to connect to CloudForms` -> `Create` -> `Add Attributes`. Fill the following attributes:

| Parameter name                  | End-user permission   | Parameter type             | Display name   |
| :---                            | :---                  | :---                       | :---           |
| username                        | Read & Write                  | string                     | Username       |
| password                        | Read & Write                  | password                   | Password       |

- Navigate to `Manage` -> `Shared parameters` -> In `Search data types`, Enter "CloudForms Authentication Details" -> Verify Data type is present
- Go to `Create data object` -> Select data type "cf_auth_details" -> Enter Data Object Name for e.g. "cf_auth_details". Fill the following paramaters.

| Parameter name                  | Type            | Parameter description
| :---                            | :---            | :---
| Username                        | string          | Username to connect to  CloudForms
| Password                        | password        | Password to connect to CloudForms

To deploy this template from Managed services, navigate to `Library` -> `Terraform templates` -> Poll CloudForms for Approval. Fill the following parameters and deploy the template.

| Parameter name                  | Type            | Parameter description      | Allowed values |
| :---                            | :---            | :---                       | :---           |
| Connection                      | connection      |             | Other |
| CloudForms Authentication Details                          | Shared Parameter          | Shared Parameter to connect to CloudForms                 | cf_auth_details|
| URL                    | string          | URL to retrieve approval status                                            | |
| CURL Option                     | string          | Options for curl command used to retrieve status from cloudform e.g. --insecure                | |
| Wait Time             | string          | Wait time in seconds i.e. time after which poll should again happen to retrieve the approval status                                                                | |

### License and Maintainer
Copyright IBM Corp. 2020

Template Version - 1.0
