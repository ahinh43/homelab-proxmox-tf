terraform {
  required_providers {
    proxmox = {
      version = "0.87.0"
      source  = "bpg/proxmox"
    }
    null = {
      version = ">= 3.0.0"
      source  = "hashicorp/null"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.14.0"
    }
  }
}
