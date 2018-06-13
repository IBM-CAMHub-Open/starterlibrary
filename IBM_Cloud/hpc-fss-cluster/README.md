# Copyright IBM Corp. 2018, 2018
# IBM Spectrum Symphony CWS/LSF Cluster Template

An [IBM Cloud Schematics](https://console.bluemix.net/docs/services/schematics/index.html) template to launch an HPC (High Performance Computing) cluster for FSS (Financial Services Sector) Tech Preview.
Schematics uses [Terraform](https://www.terraform.io/) as the infrastructure as code engine. With this template, you can provision and manage infrastructure as a single unit.
See the [Terraform provider docs](https://ibm-cloud.github.io/tf-ibm-docs/) for available resources for the IBM Cloud. **Note**: To create the resources that this template requests, your [IBM Cloud Infrastructure (Softlayer) account](https://console.bluemix.net/docs/iam/mnginfra.html#managing-infrastructure-access) and [IBM Cloud account](https://console.bluemix.net/docs/iam/mngiam.html#iammanidaccser) must have sufficient permissions.

**IMPORTANT**

Due to legal requirement, we cannot provide product packages and entitlement in this template. You must either provide your own product packages and entitlement links, or use the IBM Spectrum Cluster evaluation packages and entitlement links from the following IBM URLs, and specify those values in `uri_file_entitlement`, `uri_package_installer`, `uri_package_additional`, `uri_package_additional2` variables in the Variables section of your environment created using the hpc-fss-cluser template.

If you use the evaluation edition, after selecting "I agree" to the license and "Download using http" option, for each files listed below, right click "download now" and specify "Copy Link Address" to copy the download URL and then use that link address in the applicable `uri_` variable field. For example, copy the link address for the IBM Spectrum Symphony evaluation edition entitlement file, and use it as the `uri_file_entitlement` variable value in the environment. Repeat the process for the required evaluation edition packages listed below. The evaluation edition links are unique for each user and are only valid for a few days):

If you use IBM Passport Advantage, use the corresponding urls instead. Note that the package name will not have the word "eval".

If you host your own web or ftp service to provide the packages and entitlement, use the corresponding urls instead.

Evaluation: IBM Spectrum Symphony latest (7.2.0.0): https://www.ibm.com/marketing/iwm/iwm/web/preLogin.do?source=swerpzsw-symphony-3
  - `uri_file_entitlement`   = "https://......./sym_adv_ev_entitlement.dat"
  - `uri_package_installer`  = "https://......./symeval-7.2.0.0_x86_64.bin"
  - `uri_package_additonal`  = "https://......./symdeeval-7.2.0.0_x86_64.bin"

Evaluation: IBM Spectrum CWS latest (2.2.0.0): https://www.ibm.com/marketing/iwm/iwm/web/preLogin.do?source=swg-eipcfs
  - `uri_file_entitlement`   = "https://......./cwseval_entitlement.dat"
  - `uri_package_installer`  = "https://......./cwseval-2.2.0.0_x86_64.bin"

Evaluation: IBM Spectrum LSF latest (10.1): https://www.ibm.com/marketing/iwm/iwm/web/preLogin.do?source=swerpsysz-lsf-3&S_PKG=lsfv101
  - `uri_file_entitlement`   = (no evaluation license provided, it is embedded. leave empty for evaluation edition)
  - `uri_package_installer`  = "https://......./lsf10.1_lsfinstall_linux_x86_64.tar.Z"
  - `uri_package_additional` = "https://......./lsf10.1_linux2.6-glibc2.3-x86_64.tar."
  - `uri_package_additional2`= (no package provided; does not support Ubuntu 1604 OS)

You can provide the package with a combination of the following options:
- `uri_package_installer` (required) - The primary installer that launches Spectrum Computing cluster software. If you want to use a trial copy, use the above URL to request evaluation packages for the corresponding software.
- `uri_package_additional` (optional for CWS, required for Symphony Developer Edition, required for LSF) - A secondary installer that is used for Spectrum Computing Symphony Developer Edition or LSF Arch linux2.6-glibc2.3-x86_64 (centos7). If you want to use a trial copy, use the above URL to request evaluation packages for Symphony Developer Edition or LSF Arch linux2.6-glibc2.3-x86_64.
- `uri_package_additonal2` (optional for CWS and Symphony, required for LSF) - A secondary installer that is used for Spectrum Computing LSF Arch lnx310-glibc217-x86_64 (ubuntu1604). If you want to use a trial copy, use the above URL to request evaluation packages for LSF Arch lnx310-lib217-x86_64.

You can provide the entitlement with **either** of the following variables:
- `uri_file_entitlement` - described above for evaluation entitlement.
- `entitlement` - A string value of the pasted entitlement content. **If the entitlement contains multiple lines, you can paste line by line, adding `\n` to each line for now**.

#### Release Information

* IBM Spectrum Symphony/CWS/LSF Cluster on Schematics
* Supported Product Version: Symphony latest (7.2.0.0), CWS latest (2.2.0.0), LSF latest (10.1)

## Contents

* Default Topology
* Usage
* Advanced Usage
* Community Contribution
* Release Notes
* Copyright

## Default Topology

Review the following diagrams for the topology of default symphony, cws, and lsf clusters.

### Default Symphony cluster

![default installation topology](https://raw.githubusercontent.com/IBMSpectrumComputing/spectrum-schematics-cluster/master/images/symdefault.png)

### Default CWS cluster

![default installation topology](https://raw.githubusercontent.com/IBMSpectrumComputing/spectrum-schematics-cluster/master/images/cwsdefault.png)

### Default LSF cluster

![default installation topology](https://raw.githubusercontent.com/IBMSpectrumComputing/spectrum-schematics-cluster/master/images/lsfdefault.png)

## Usage

### Create an environment with IBM Cloud Schematics
Environments can be used to separate software components into development tiers (e.g. staging, QA, and production).
1. In IBM Cloud, go to the menu and select the [Schematics dashboard](https://console.bluemix.net/schematics).
2. In the left navigation menu, select **Templates** to access the template catalog.
3. Click **Create** on the hpc-fss-cluster template. You are taken to a configuration page where you can define metadata about your environment.
4. Define values for your variables according to the following table.

### Create an environment with Terraform Binary on your local workstation
1. [Set up IBM Cloud provider credentials](#setting-up-provider-credentials) on your local machine.
2. Install the [Terraform binary](https://www.terraform.io/intro/getting-started/install.html)
3. Install the [IBM Cloud Provider Plugin](https://github.com/IBM-Bluemix/terraform-provider-ibm).
4. Follow the instructions at the [IBM Cloud Provider for Terraform docs](https://ibm-bluemix.github.io/tf-ibm-docs/index.html).

To run this project locally:

1. Supply the required variable values in one of the following ways:
    * via the [command line](https://www.terraform.io/intro/getting-started/variables.html#command-line-flags)
    * in a [`terraform.tfvars` file](https://www.terraform.io/intro/getting-started/variables.html#from-a-file)
    * via [environment variables](https://www.terraform.io/intro/getting-started/variables.html#from-environment-variables)
2. Run `terraform plan`. Terraform performs a dry run to show what resources will be created.
3. Run `terraform apply`. Terraform creates and deploys resources to your environment.
    * You can see deployed infrastructure in IBM Cloud [here](https://control.bluemix.net/devices).
4. Run `terraform destroy`. Terraform destroys all deployed resources in this environment.

### Variables
|Variable Name|Description|Default Value|
|-------------|-----------|-------------|
|bluemix_api_key|Your IBM Cloud API key. You can get the value by running `bx iam api-key-create <key name>``.||
|cluster_admin|The administrator account of the cluster: `egoadmin` or `lsfadmin`.|egoadmin|
|cluster_name|The name of the cluster.|mycluster|
|cluster_web_admin_password|Password for web interface account Admin|Admin|
|core_of_compute|The number of CPU cores to allocate to the compute server.|1|
|core_of_master|The number of CPU cores to allocate to the master server.|2|
|datacenter_bare_metal|The data center to create bare metal resources in. You can get the list by running `bluemix cs locations`.|wdc04|
|datacenter|The data center to create resources in. You can get the list by running `bluemix cs locations`.|dal12|
|private_vlan_id|(advanced)The private vlan to create vm resources in. defaults to 0 for automatic placement.|0|
|domain_name|The name of the domain for the instance.|domain.com|
|entitlement|Entitlement content that enables use of the cluster software.||
|fixed_config_preset|The bare metal hardware configuration.|S1270_32GB_2X960GBSSD_NORAID|
|hourly_billing_compute|The billing type for the instance. When set to true, the computing instance is billed on hourly usage. Otherwise, the instance is billed on a monthly basis.|true|
|hourly_billing_master|The billing type for the instance. When set to true, the master node is billed on hourly usage. Otherwise, the instance is billed on a monthly basis.|true|
|failover_master|(advanced)Specifies whether or not HA is enabled for master nodes.|false|
|master_use_bare_metal|(advanced)If set to `true`, bare metal masters are created. If set to `false`, VM masters are created.|false|
|memory_in_mb_compute|The amount of memory (in Mb) to allocate to the compute server.|4096|
|memory_in_mb_master|The amount of memory (in Mb) to allocate to the master server.|8192|
|network_speed_compute|The network interface speed for the compute nodes.|1000|
|network_speed_master|The network interface speed for the master nodes.|1000|
|number_of_compute_bare_metal|(advanced)The number of bare metal compute nodes to deploy.|0|
|number_of_compute|The number of VM compute nodes to deploy.|2|
|number_of_dehost|The number of development nodes to depoy.|1|
|os_reference_bare_metal|An operating system reference code that is used to provision the bare metal server.|UBUNTU_16_64|
|os_reference|An operating system reference code that is used to provision the cluster nodes. Get a complete list of the OS reference codes available (use your API key as the password to log in).|CENTOS_7_64|
|image_id|(advanced)speicfy the image id for vm instances. defaults to 0 meaning use os_reference instead|0|
|post_install_script_uri|The URI for the deployment script.|https://raw.githubusercontent.com/IBMSpectrumComputing/spectrum-schematics-cluster/master/scripts/ibm_spectrum_computing_deploy.sh|
|prefix_compute_bare_metal|The hostname prefix for bare metal compute nodes.|bmcompute|
|prefix_compute|The hostname prefix for compute nodes.|compute|
|prefix_dehost|The hostname prefix for Symphony development nodes.|dehost|
|prefix_master|The hostname prefix for the master server.|master|
|product|The cluster product to deploy: `symphony`, `cws`, or `lsf`.|symphony|
|softlayer_api_key|Your IBM Cloud Infrastructure (SoftLayer) API key.||
|softlayer_username|Your IBM Cloud Infrastructure (SoftLayer) user name.||
|ssh_key_label|An identifying label to assign to the SSH key.|ssh_compute_key|
|ssh_key_note|A description to assign to the SSH key.|ssh key for cluster hosts|
|ssh_public_key|The public key contents for the SSH keypair to access cluster nodes.||
|uri_file_entitlement|The URL to the entitlement file for the software product.||
|uri_package_additional|The URL to the product package supplement file.||
|uri_package_additional2|The URL to an additional product package supplement file.||
|uri_package_installer|The URL to the product package installation file.||
|use_intranet|(advanced)Specifies whether the cluster resolves hostnames with intranet or internet IP addresses.|true|
|version|The version of the cluster product: `latest`, `7.2.0.0`, `2.2.0.0`, or `10.1`.|latest|

## Advanced Usage

### Cluster HA 

To enable master failover, set `failover_master` to 1 or true

Currently, the failover implements only when master is virtual, it brings up a virtual as nfs server
- to ensure nfs server and masters are in the same VLAN, you might need to specify `private_vlan_id` when you have multiple vlans in a specific datacenter

### Bare metal support

Use standalone ibm-cloud-provider and Terraform to deploy bare metal servers. Since `datacenter` and `fixed_config_preset` must be specified and there is no guarantee of availability, you may need to try several different values.

You can use `D2620V4_128GB_2X800GB_SSD_RAID_1_K80_GPU2` as a GPU preset.

When deploying bare metal servers, these variables can be especially useful:
- master_use_bare_metal - If set to `true`, bare metal masters are created. If set to `false`, VM masters are created.
- number_of_compute_bare_metal - The number of bare metal compute nodes to deploy.
- datacenter_bare_metal - The data center to create resources in. You can get the list by running `bluemix cs locations`.
- os_reference_bare_metal - An operating system reference code that is used to provision the bare metal server.

## Community Contribution Requirements

Community contributions to this repository must follow the [IBM Developer's Certificate of Origin (DCO)](https://github.com/IBMSpectrumComputing/spectrum-schematics-cluster/blob/master/IBMDCO.md) process. Contributions can only through GitHub pull requests:

 1. Contributor proposes new code to community through a pull request.

 2. Contributor signs off on contributions by attaching the DCO to ensure contributor is either the code originator or has rights to publish. The template of the DCO is included in this package.

 3. IBM SpectrumComputing reviews the contribution to check for:
    i)  Applicability and relevancy of functional content
    ii) Any obvious issues

 4. If accepted, the contribution is merged. If rejected, the contribution goes back to contributor and is not merged.

 ## Release Notes

 ### version 0.5.0

 - add option to create and specify private vlan for vm instances
 - ssh_private_key no longer needed for bare metal deployment
 - add paramters for evaluation clusters:
 - uri_file_entitlement
 - uri_package_installer
 - uri_package_additonal
 - uri_package_additional2

 ### version 0.4

 - Boost version to 0.4 to catchup provider version
 - Support **symphony**, **cws** and **lsf deployment**
 - Support both **CENTOS_7_64** and **UBUNTU_16_64**
 - Bare metal support (experimental)
   - **never create bare metals with the same hostname and domainname in the same day even after destroy**
   - bare metal creation require to specify datacenter and preset fixed config, no guarantee of availability
   - **master_use_bare_metal** or **number_of_compute_bare_metal**

 ### Release initial

 - This is the first release from IBM Spectrum Computing.
 - Create centos based symphony 7.2.0.0 virtual machines on SoftLayer using Schematics.
 - Required variables
   - **entitlement**
   - **ibm_bmx_api_key**
   - **ibm_sl_username**, **ibm_sl_api_key**
   - **ssh_public_key**

## Copyright

### EPL v1.0

    Eclipse Public License - v 1.0

THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE
PUBLIC LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR DISTRIBUTION OF
THE PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THIS AGREEMENT.

*1. DEFINITIONS*

"Contribution" means:

a) in the case of the initial Contributor, the initial code and
documentation distributed under this Agreement, and

b) in the case of each subsequent Contributor:

i) changes to the Program, and

ii) additions to the Program;

where such changes and/or additions to the Program originate from and
are distributed by that particular Contributor. A Contribution
'originates' from a Contributor if it was added to the Program by such
Contributor itself or anyone acting on such Contributor's behalf.
Contributions do not include additions to the Program which: (i) are
separate modules of software distributed in conjunction with the Program
under their own license agreement, and (ii) are not derivative works of
the Program.

"Contributor" means any person or entity that distributes the Program.

"Licensed Patents" mean patent claims licensable by a Contributor which
are necessarily infringed by the use or sale of its Contribution alone
or when combined with the Program.

"Program" means the Contributions distributed in accordance with this
Agreement.

"Recipient" means anyone who receives the Program under this Agreement,
including all Contributors.

*2. GRANT OF RIGHTS*

a) Subject to the terms of this Agreement, each Contributor hereby
grants Recipient a non-exclusive, worldwide, royalty-free copyright
license to reproduce, prepare derivative works of, publicly display,
publicly perform, distribute and sublicense the Contribution of such
Contributor, if any, and such derivative works, in source code and
object code form.

b) Subject to the terms of this Agreement, each Contributor hereby
grants Recipient a non-exclusive, worldwide, royalty-free patent license
under Licensed Patents to make, use, sell, offer to sell, import and
otherwise transfer the Contribution of such Contributor, if any, in
source code and object code form. This patent license shall apply to the
combination of the Contribution and the Program if, at the time the
Contribution is added by the Contributor, such addition of the
Contribution causes such combination to be covered by the Licensed
Patents. The patent license shall not apply to any other combinations
which include the Contribution. No hardware per se is licensed hereunder.

c) Recipient understands that although each Contributor grants the
licenses to its Contributions set forth herein, no assurances are
provided by any Contributor that the Program does not infringe the
patent or other intellectual property rights of any other entity. Each
Contributor disclaims any liability to Recipient for claims brought by
any other entity based on infringement of intellectual property rights
or otherwise. As a condition to exercising the rights and licenses
granted hereunder, each Recipient hereby assumes sole responsibility to
secure any other intellectual property rights needed, if any. For
example, if a third party patent license is required to allow Recipient
to distribute the Program, it is Recipient's responsibility to acquire
that license before distributing the Program.

d) Each Contributor represents that to its knowledge it has sufficient
copyright rights in its Contribution, if any, to grant the copyright
license set forth in this Agreement.

*3. REQUIREMENTS*

A Contributor may choose to distribute the Program in object code form
under its own license agreement, provided that:

a) it complies with the terms and conditions of this Agreement; and

b) its license agreement:

i) effectively disclaims on behalf of all Contributors all warranties
and conditions, express and implied, including warranties or conditions
of title and non-infringement, and implied warranties or conditions of
merchantability and fitness for a particular purpose;

ii) effectively excludes on behalf of all Contributors all liability for
damages, including direct, indirect, special, incidental and
consequential damages, such as lost profits;

iii) states that any provisions which differ from this Agreement are
offered by that Contributor alone and not by any other party; and

iv) states that source code for the Program is available from such
Contributor, and informs licensees how to obtain it in a reasonable
manner on or through a medium customarily used for software exchange.

When the Program is made available in source code form:

a) it must be made available under this Agreement; and

b) a copy of this Agreement must be included with each copy of the Program.

Contributors may not remove or alter any copyright notices contained
within the Program.

Each Contributor must identify itself as the originator of its
Contribution, if any, in a manner that reasonably allows subsequent
Recipients to identify the originator of the Contribution.

*4. COMMERCIAL DISTRIBUTION*

Commercial distributors of software may accept certain responsibilities
with respect to end users, business partners and the like. While this
license is intended to facilitate the commercial use of the Program, the
Contributor who includes the Program in a commercial product offering
should do so in a manner which does not create potential liability for
other Contributors. Therefore, if a Contributor includes the Program in
a commercial product offering, such Contributor ("Commercial
Contributor") hereby agrees to defend and indemnify every other
Contributor ("Indemnified Contributor") against any losses, damages and
costs (collectively "Losses") arising from claims, lawsuits and other
legal actions brought by a third party against the Indemnified
Contributor to the extent caused by the acts or omissions of such
Commercial Contributor in connection with its distribution of the
Program in a commercial product offering. The obligations in this
section do not apply to any claims or Losses relating to any actual or
alleged intellectual property infringement. In order to qualify, an
Indemnified Contributor must: a) promptly notify the Commercial
Contributor in writing of such claim, and b) allow the Commercial
Contributor to control, and cooperate with the Commercial Contributor
in, the defense and any related settlement negotiations. The Indemnified
Contributor may participate in any such claim at its own expense.

For example, a Contributor might include the Program in a commercial
product offering, Product X. That Contributor is then a Commercial
Contributor. If that Commercial Contributor then makes performance
claims, or offers warranties related to Product X, those performance
claims and warranties are such Commercial Contributor's responsibility
alone. Under this section, the Commercial Contributor would have to
defend claims against the other Contributors related to those
performance claims and warranties, and if a court requires any other
Contributor to pay any damages as a result, the Commercial Contributor
must pay those damages.

*5. NO WARRANTY*

EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE PROGRAM IS PROVIDED
ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES
OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. Each Recipient is solely responsible for
determining the appropriateness of using and distributing the Program
and assumes all risks associated with its exercise of rights under this
Agreement , including but not limited to the risks and costs of program
errors, compliance with applicable laws, damage to or loss of data,
programs or equipment, and unavailability or interruption of operations.

*6. DISCLAIMER OF LIABILITY*

EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER RECIPIENT NOR
ANY CONTRIBUTORS SHALL HAVE ANY LIABILITY FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING
WITHOUT LIMITATION LOST PROFITS), HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OR
DISTRIBUTION OF THE PROGRAM OR THE EXERCISE OF ANY RIGHTS GRANTED
HEREUNDER, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

*7. GENERAL*

If any provision of this Agreement is invalid or unenforceable under
applicable law, it shall not affect the validity or enforceability of
the remainder of the terms of this Agreement, and without further action
by the parties hereto, such provision shall be reformed to the minimum
extent necessary to make such provision valid and enforceable.

If Recipient institutes patent litigation against any entity (including
a cross-claim or counterclaim in a lawsuit) alleging that the Program
itself (excluding combinations of the Program with other software or
hardware) infringes such Recipient's patent(s), then such Recipient's
rights granted under Section 2(b) shall terminate as of the date such
litigation is filed.

All Recipient's rights under this Agreement shall terminate if it fails
to comply with any of the material terms or conditions of this Agreement
and does not cure such failure in a reasonable period of time after
becoming aware of such noncompliance. If all Recipient's rights under
this Agreement terminate, Recipient agrees to cease use and distribution
of the Program as soon as reasonably practicable. However, Recipient's
obligations under this Agreement and any licenses granted by Recipient
relating to the Program shall continue and survive.

Everyone is permitted to copy and distribute copies of this Agreement,
but in order to avoid inconsistency the Agreement is copyrighted and may
only be modified in the following manner. The Agreement Steward reserves
the right to publish new versions (including revisions) of this
Agreement from time to time. No one other than the Agreement Steward has
the right to modify this Agreement. The Eclipse Foundation is the
initial Agreement Steward. The Eclipse Foundation may assign the
responsibility to serve as the Agreement Steward to a suitable separate
entity. Each new version of the Agreement will be given a distinguishing
version number. The Program (including Contributions) may always be
distributed subject to the version of the Agreement under which it was
received. In addition, after a new version of the Agreement is
published, Contributor may elect to distribute the Program (including
its Contributions) under the new version. Except as expressly stated in
Sections 2(a) and 2(b) above, Recipient receives no rights or licenses
to the intellectual property of any Contributor under this Agreement,
whether expressly, by implication, estoppel or otherwise. All rights in
the Program not expressly granted under this Agreement are reserved.

This Agreement is governed by the laws of the State of New York and the
intellectual property laws of the United States of America. No party to
this Agreement will bring a legal action under this Agreement more than
one year after the cause of action arose. Each party waives its rights
to a jury trial in any resulting litigation.
