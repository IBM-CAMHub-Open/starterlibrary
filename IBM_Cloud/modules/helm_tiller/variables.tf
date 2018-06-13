variable "cluster_name" {
  description = "Cluster name or ID."
}
variable "cluster_config" {
  description = "Base64 encoded cluster configuration."
}
variable "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority used to connect to the cluster."
}
variable "helm_version" {
  description = "Helm version to be used to deploy the tiller into the Kubernetes cluster"
}