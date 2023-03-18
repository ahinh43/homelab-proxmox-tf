variable "proxmox_username" {
  description = "Username to authenticate to proxmox with."
  type        = string
}

variable "proxmox_password" {
  description = "The password of the proxmox user"
  type        = string
}

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

variable "k8s_certificate_key" {
  description = "Cert key for joining new masters to the cluster"
  type        = string
  default     = null
}

variable "cloudflare_api_token" {
  description = "API token to authenticate to Cloudflare"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Account ID to cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for cloudflare"
  type        = string
}
