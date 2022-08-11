locals {
  vm_ip_address = var.vm_ip_address
}

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

  dynamic "disk" {
    for_each = var.additional_disk_configurations != null ? var.additional_disk_configurations : []
    content {
      type    = "scsi"
      storage = disk.storage_name
      size    = disk.storage_size
    }
  }

  automatic_reboot = false

  lifecycle {
    ignore_changes = [
      ipconfig0,
      disk
    ]
  }

}
resource "null_resource" "custom_ip_address" {
  triggers = {
    server = local.vm_ip_address
  }

  connection {
    type        = "ssh"
    user        = "core"
    private_key = var.ssh_private_key
    host        = proxmox_vm_qemu.main.default_ipv4_address
  }
  provisioner "file" {
    source      = "${path.module}/provisioning/flatcar-set-custom-ip.sh"
    destination = "/tmp/flatcar-set-custom-ip.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/flatcar-set-custom-ip.sh ${var.vm_ip_address} ${var.vm_subnet_cidr} ${var.vm_gateway_ip} ${var.vm_primary_dns_server} ${var.vm_secondary_dns_server}"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
    ssh core@${proxmox_vm_qemu.main.default_ipv4_address} '(sleep 2; sudo systemctl restart systemd-networkd)&'; sleep 3
    until ssh core@${local.vm_ip_address} -o ConnectTimeout=2 'true 2> /dev/null'
    do
      echo "Waiting for the IP to change..."
      sleep 2
    done
    EOT
  }

  depends_on = [
    proxmox_vm_qemu.main
  ]
}

resource "null_resource" "kube_provision" {
  triggers = {
    server = local.vm_ip_address
  }

  connection {
    type        = "ssh"
    user        = "core"
    private_key = var.ssh_private_key
    host        = local.vm_ip_address
  }

  provisioner "file" {
    source      = "${path.module}/provisioning/kubernetes-${var.kubernetes_type}.sh"
    destination = "/tmp/kubernetes-${var.kubernetes_type}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /bin/hostnamectl set-hostname ${var.vm_name}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/kubernetes-${var.kubernetes_type}.sh ${var.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
    ]
  }

  depends_on = [
    null_resource.custom_ip_address
  ]
}