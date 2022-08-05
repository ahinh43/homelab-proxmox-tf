terraform {
  cloud {
    organization = "ahinh43"

    workspaces {
      name = "proxmox"
    }
  }
}