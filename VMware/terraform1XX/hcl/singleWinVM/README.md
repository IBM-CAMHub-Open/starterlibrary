<!---
Copyright IBM Corp. 2018, 2018
--->

# VMware Windows Virtual Machine Provision

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| count |  | string | `1` | no |
| dependsOn | Boolean for dependency | string | `true` | no |
| vm_adapter_type | Network adapter type for vNIC Configuration | string | `vmxnet3` | no |
| vm_disk1_datastore | Data store or storage cluster name for target virtual machine's disks | string | - | yes |
| vm_disk1_keep_on_remove | Delete template disk volume when the virtual machine is deleted | string | `false` | no |
| vm_disk1_size | Size of template disk volume | string | - | yes |
| vm_dns_servers | DNS servers for the virtual network adapter | list | - | yes |
| vm_domain | Domain Name of virtual machine | string | - | yes |
| vm_folder | Target vSphere folder for virtual machine | string | - | yes |
| vm_ipv4_address | IPv4 address for vNIC configuration | list | - | yes |
| vm_ipv4_gateway | IPv4 gateway for vNIC configuration | string | - | yes |
| vm_ipv4_prefix_length | IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32 | string | - | yes |
| vm_memory | Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024 | string | `1024` | no |
| vm_name | Variable : vm_-name | string | - | yes |
| vm_network_interface_label | vSphere port group or network label for virtual machine's vNIC | string | - | yes |
| admin_password | Operating System Password for the Operating System User to access virtual machine | string | - | yes |
| vm_template | Target vSphere folder for virtual machine | string | - | yes |
| vm_vcpu | Number of virtual CPU for the virtual machine, which is required to be a positive Integer | string | `1` | no |
| vsphere_datacenter | Target vSphere datacenter for virtual machine creation | string | - | yes |
| vsphere_resource_pool | Target vSphere Resource Pool to host the virtual machine | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter when Module Complete |
| address | Output VM IPv4 address |
