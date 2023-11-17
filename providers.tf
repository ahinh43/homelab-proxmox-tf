provider "proxmox" {
  pm_api_url  = "https://proxmox.labs.ahinh.me:8006/api2/json"
  pm_user     = var.proxmox_username
  pm_password = var.proxmox_password
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}