terraform {
  required_providers {
    proxmox = {
      version = ">= 0.38.0"
      source  = "bpg/proxmox"
    }
    null = {
      version = ">= 3.0.0"
      source  = "hashicorp/null"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "= 4.20.0"
    }
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = ">= 2.2.2"
    }
  }
}
