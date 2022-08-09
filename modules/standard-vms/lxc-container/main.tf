resource "proxmox_lxc" "main" {
  target_node   = var.target_node
  hostname      = var.name
  clone         = var.template_vmid
  clone_storage = var.clone_storage
  cores         = var.cpu_cores
  memory        = var.memory
  swap          = var.memory
  onboot        = true

  start        = true
  unprivileged = true
  full         = true

  // Terraform will crash without rootfs defined
  rootfs {
    storage = var.clone_storage
    size    = var.root_disk_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  provisioner "file" {
    source      = "${path.module}/../provisioning/ubuntu-standard.sh"
    destination = "/tmp/ubuntu-standard.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/ubuntu-standard.sh"
    ]
  }

  # provisioner {
  #   dynamic "file" {
  #     for_each = var.provision_minecraft ? [true] : []
  #     content {
  #       source      = "${path.module}/../provisioning/minecraft/minecraft-java-${var.minecraft_jre_version}-standard.sh"
  #       destination = "/tmp/provision_minecraft_standard.sh"
  #     }
  #   }
  #   dynamic "remote-exec" {
  #     for_each = var.provision_minecraft ? [true] : []
  #     content {
  #       inline = [
  #         "sudo -E -S /bin/bash /tmp/provision_minecraft_standard.sh"
  #       ]
  #     }
  #   }
  # }
}