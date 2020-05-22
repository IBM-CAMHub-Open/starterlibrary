
module "cluster" {
  source  = "git::https://github.com/IBM-CAMHub-Open/starterlibrary.git?ref=2.2//IBM_Cloud/modules/ibm_cloud_kubernetes_cluster"
  org = "${var.org}"
  space = "${var.space}" 
  cluster_name = "${var.cluster_name}" 
  region = "${var.region}" 
  datacenter = "${var.datacenter}" 
  num_workers = "${var.num_workers}"
  machine_type = "${var.machine_type}" 
  isolation = "${var.isolation}" 
  private_vlan_id = "${var.private_vlan_id}" 
  public_vlan_id = "${var.public_vlan_id}" 
  subnet_id = "${var.subnet_id}" 
  resource_group_name = "${var.resource_group_name}" 
  kube_version = "${var.kube_version}" 
}

module "tiller" {
  source  = "git::https://github.com/IBM-CAMHub-Open/starterlibrary.git?ref=2.2//IBM_Cloud/modules/helm_tiller"
  deploy_tiller = "${var.deploy_tiller}"
  cluster_name = "${var.cluster_name}"
  cluster_config = "${module.cluster.cluster_config}"
  cluster_certificate_authority = "${module.cluster.cluster_certificate_authority}"
  helm_version = "${var.helm_version}"
}