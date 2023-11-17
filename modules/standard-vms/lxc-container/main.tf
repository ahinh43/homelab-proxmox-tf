locals {
  shell_path = var.os_family == "alpine" ? "/usr/bin/env ash" : "/usr/bin/env bash"
}
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
    source      = "${path.module}/../provisioning/${var.os_family}-standard.sh"
    destination = "/tmp/${var.os_family}-standard.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S ${local.shell_path} /tmp/${var.os_family}-standard.sh ${var.name}"
    ]
  }
  lifecycle {
    ignore_changes = [target_node]
  }
}

resource "null_resource" "minecraft" {
  count = var.provision_minecraft ? 1 : 0
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
      "sudo -E -S ${local.shell_path} /tmp/minecraft-java-standard.sh ${var.minecraft_jre_version} ${var.minecraft_jre_min_mem} ${var.minecraft_jre_max_mem} ${var.minecraft_server_type} ${var.minecraft_server_version}"
    ]
  }

  depends_on = [
    proxmox_lxc.main
  ]
}

module "vm_dns_record" {
  count         = var.create_dns_record ? 1 : 0
  source        = "../../cloudflare_dns_record"
  zone_id       = var.cloudflare_zone_id
  record_name   = "${var.name}.labs"
  record_target = var.ip_address
}