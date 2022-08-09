resource "proxmox_lxc" "main" {
  target_node = var.target_node
  hostname    = var.name
  clone       = var.template_vmid
  cores       = var.cpu_cores
  memory      = var.memory
  swap        = var.memory
  onboot      = true

  start        = true
  unprivileged = true
  full         = true

  // Terraform will crash without rootfs defined
  rootfs {
    storage = var.clone_storage
    size    = "${var.root_disk_size}G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.ip_address}/24"
    gw     = "10.1.1.1"
  }

  connection {
    type        = "ssh"
    user        = "ahinh"
    private_key = var.ssh_private_key
    host        = var.ip_address
  }

  provisioner "file" {
    source      = "${path.module}/../provisioning/ubuntu-standard.sh"
    destination = "/tmp/ubuntu-standard.sh ${var.name}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/ubuntu-standard.sh"
    ]
  }
}

resource "null_resource" "minecraft" {
  triggers = {
    server = var.ip_address
  }

  connection {
    type        = "ssh"
    user        = "ahinh"
    private_key = var.ssh_private_key
    host        = var.ip_address
  }

  provisioner "file" {
    source      = "${path.module}/../provisioning/minecraft/minecraft-java-standard.sh"
    destination = "/tmp/minecraft-java-standard.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../provisioning/minecraft/get-forge-version.py"
    destination = "/tmp/get-forge-version.py"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/minecraft-java-standard.sh ${var.minecraft_jre_version} ${var.minecraft_jre_min_mem} ${var.minecraft_jre_max_mem} ${var.minecraft_server_type} ${var.minecraft_server_version}"
    ]
  }

  depends_on = [
    proxmox_lxc.main
  ]
}