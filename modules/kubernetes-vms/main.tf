resource "proxmox_vm_qemu" "main" {
  name        = var.vm_name
  target_node = var.target_node
  clone       = var.template_name
  memory      = var.vm_memory
  sockets     = var.vm_cpu_sockets
  cores       = var.vm_cpu_cores
  agent       = var.enable_agent ? 1 : 0

  network {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
    queues   = 0
    rate     = 0
    mtu      = 0
  }

  automatic_reboot = false

  connection {
    type        = "ssh"
    user        = "core"
    private_key = var.ssh_private_key
    host        = self.default_ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/provisioning/kubernetes-${var.kubernetes_type}.sh"
    destination = "/tmp/kubernetes-${var.kubernetes_type}.sh"
  }
  # provisioner "remote-exec" {
  #   inline = [
  #     "echo \"export KUBERNETES_APPLY=${var.my_var}\" >> ~/.bashrc"
  #   ]
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo -E "
  #   ]
  # }
}