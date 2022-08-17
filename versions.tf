terraform {
  required_providers {
    proxmox = {
      version = ">= 2.9.10"
      source  = "Telmate/proxmox"
    }
    null = {
      version = ">= 3.0.0"
      source  = "hashicorp/null"
    }
  }
}
