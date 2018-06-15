module "tiller" {
  source  = "git::https://github.com/IBM-CAMHub-Open/starterlibrary.git?ref=2.0//IBM_Cloud/modules/helm_tiller"
  cluster_name = "${var.cluster_name}"
  cluster_config = "${var.cluster_config}"
  cluster_certificate_authority = "${var.cluster_certificate_authority}"
  helm_version = "${var.helm_version}"
}