# IBM Cloud Kubernetes Service
# Copyright IBM Corp. 2018, 2018
An IBM Cloud Schematics template to provision a Kubernetes cluster with _N_ worker nodes in IBM Cloud. Schematics uses [Terraform](https://www.terraform.io/) as the infrastructure as code engine. With this template, you can provision and manage infrastructure as a single unit. **Note**: To create the resources that this template requests, your [IBM Cloud Infrastructure (Softlayer) account](https://console.bluemix.net/docs/iam/mnginfra.html#managing-infrastructure-access) and [IBM Cloud account](https://console.bluemix.net/docs/iam/mngiam.html#iammanidaccser) must have sufficient permissions.

See the IBM Cloud docs for more information about [Schematics](https://console.bluemix.net/docs/services/schematics/index.html) and the [IBM Cloud Container Service](https://console.bluemix.net/docs/containers/container_index.html).

## Create an environment with this template

Environments can be used to separate software components into development tiers (e.g. staging, QA, and production).

1. In IBM Cloud, go to the menu and select the [Schematics dashboard](https://console.bluemix.net/schematics).
2. In the left navigation menu, select **Templates** to access the template catalog.
3. Click **Create** on the containers cluster template. You are taken to a configuration page where you can define data about your environment.
4. Define values for your variables according to the following table.

### Variables

|Variable Name|Description|Default Value|
|-------------|-----------|-------------|
|bluemix_api_key|Your IBM Cloud API key. You can get the value by running `bx iam api-key-create <key name>`.||
|cluster_name| The base name for the cluster. |kubecluster|
|datacenter| The data center for the cluster, You can get the list with by running `bluemix cs locations`. |dal12|
|machine_type| The CPU cores, memory, network, and speed. You can get a list for a given location by running `bluemix cs machine-types <location>`. |u2c.2x4|
|num_workers| The number of worker nodes in the cluster. |2|
|org| Your IBM Cloud org name.||
|private_vlan_id| The private VLAN for your account. You can run `bx cs vlans <location>`. ||
|public_vlan_id| The public VLAN for your account. You can run `bx cs vlans <location>`.||
|region| The [IBM Cloud region](https://console.bluemix.net/docs/containers/cs_regions.html#regions-and-locations) where you want to deploy your cluster. |us-south|
|space| Your IBM Cloud space name.|dev|
|subnet_id| The portable subnet to use for cluster. You can view a list of available subnets by running `bx cs subnets`.||

**NOTE:** The `num_workers` variable has to be a value between 1 and 10. All worker nodes in the cluster are assigned the name 'worker-_N_'. It is not possible to change the base name of worker nodes with this template.

## Next steps

After setting up your environment with this template, you can run **Plan** to preview how Schematics will deploy resources (in this case, a Kubernetes cluster) to your environment. When you are ready to deploy the cluster, run **Apply**.
