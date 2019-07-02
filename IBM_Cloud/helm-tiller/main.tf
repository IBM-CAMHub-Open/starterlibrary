module "tiller" {
  source  = "git::https://github.com/IBM-CAMHub-Open/template_kubernetes_iks.git?ref=1.11//terraform/modules/helm_tiller"
  cluster_name = "${var.cluster_name}"
  cluster_config = "${var.cluster_config}"
  cluster_certificate_authority = "${var.cluster_certificate_authority}"
  helm_version = "${var.helm_version}"
}