resource "proxmox_virtual_environment_pool" "kubernetes" {
  comment = "Kubernetes nodes. Not backed up in PBS. - Managed by Terraform"
  pool_id = "kubernetes-nodes"
}

resource "proxmox_virtual_environment_pool" "lxc-general" {
  comment = "General use LXC containers. Backed up in PBS. - Managed by Terraform"
  pool_id = "lxc-general"
}