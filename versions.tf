terraform {
  required_providers {
    proxmox = {
      version = ">= 2.9.10"
      source  = "Telmate/proxmox"
    }
    onepassword = {
      version = ">= 1.1.4"
      source  = "1password/onepassword"
    }
  }
}
