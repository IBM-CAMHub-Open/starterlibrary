## Usage notes for `Single Virtual Machine using predefined tags` template

This template showcases how to associate tags to a VMware vSphere resource. This template assumes that the tag category name (tag key) and tag name (tag value) already exists in VMware vSphere. This template is tailored to work with the service created in the IBM Cloud Pak for Multicloud Management Managed service. This template will filter out tags `environment` and `request_user` service tags from the list of tags set by service and pass it on to VMware vSphere. 

### Pre-requisites

1. On VMware vSphere, create the tag category `environment` and `request_user`.
2. On VMware vSphere, create the tags under category `environment` and `request_user`. The tag names must match the value that you will set during service deployment.

### Customization

If you want to associate any additional tags (other than `environment` and `request_user`) then you must 

1. Change the variable `service_tag_includes` in the `main.tf` template and add the new tag category (tag key) to the `default` list attribute.
2. On VMware vSphere, create the new tag category.
3. On VMware vSphere, create the tags under this new category. The tag names must match the value that you will set during service deployment.


