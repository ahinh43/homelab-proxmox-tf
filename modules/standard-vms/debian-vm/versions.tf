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
  }
}
