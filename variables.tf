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

variable "k8s_cluster_information" {
  description = "A list of k8s cluster objects to allow other nodes to join a k8s cluster"
  type = list(object({
    cluster_endpoint_name = string
    cluster_token         = string
    cacert_hash           = string
    certificate_key       = string
  }))
  default = []
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
