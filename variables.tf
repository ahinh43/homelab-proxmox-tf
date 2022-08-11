variable "ssh_private_key" {
  description = "SSH private key string"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for new VMs"
  type        = string
}

variable "k8s_cluster_token" {
  description = "Cluster token of the Kubernetes cluster. Required if operating with K8s"
  type        = string
  default     = null
}

variable "k8s_cacert_hash" {
  description = "CA Cert hash for the kubernetes cluster. Required if operating with k8s"
  type        = string
  default     = null
}