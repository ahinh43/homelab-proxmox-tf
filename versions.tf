terraform {
  required_providers {
    proxmox = {
      version = "0.89.1"
      source  = "bpg/proxmox"
    }
    null = {
      version = ">= 3.0.0"
      source  = "hashicorp/null"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.12.0"
    }
  }
}
