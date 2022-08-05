locals {
  proxmox_compute_nodes = [
    "shizuru",
    "nia",
    "grace"
  ]
}


resource "proxmox_vm_qemu" "flatcar-test" {
  name        = "flatcar-test"
  target_node = local.proxmox_compute_nodes[0]
  clone       = "flatcar-template-current"
  memory      = 2048
  sockets     = 2
  cores       = 1
  agent       = 1

  network {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
    queues   = 0
    rate     = 0
    mtu      = 0
  }
  automatic_reboot = true

  connection {
    type        = "ssh"
    user        = "core"
    private_key = var.ssh_private_key
    host        = self.default_ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'hello world'"
    ]
  }
}