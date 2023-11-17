terraform {
  required_providers {
    proxmox = {
      version = ">= 0.38.0"
      source  = "bpg/proxmox"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.1.0"
    }
  }
}
