provider "proxmox" {
  endpoint = "https://proxmox.labs.ahinh.me:8006/api2/json"
  username = var.proxmox_username
  password = var.proxmox_password
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}