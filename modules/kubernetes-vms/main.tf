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


data "template_file" "controller" {
  count    = (var.kubernetes_type == "controller" && var.kubernetes_cluster_token != null) ? 1 : 0
  template = file("${path.module}/provisioning/kubeadm-templates/join-controller.yaml.tpl")
  vars = {
    kubernetes_cluster_endpoint           = "${var.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
    kubernetes_cluster_token              = var.kubernetes_cluster_token
    kubernetes_cluster_cacert_hash        = var.kubernetes_cacert_hash
    kubernetes_controller_local_endpoint  = "${local.vm_ip_address}:${var.kubernetes_api_port}"
    kubernetes_controller_certificate_key = var.kubernetes_cluster_certificate_key
  }
}

resource "null_resource" "kube_join_provision" {
  count = (var.kubernetes_type == "controller" || var.kubernetes_type == "worker") ? 1 : 0
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

  provisioner "file" {
    content     = data.template_file.controller[0].rendered
    destination = "/tmp/join-${var.kubernetes_type}.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /bin/hostnamectl set-hostname ${var.vm_name}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/kubernetes-${var.kubernetes_type}.sh"
    ]
  }

  depends_on = [
    null_resource.custom_ip_address
  ]
}

resource "random_password" "certificate_key" {
  count   = var.kubernetes_type == "primary-controller" ? 1 : 0
  length  = 48
  special = false
}

resource "null_resource" "kube_primary_controller_provision" {
  count = var.kubernetes_type == "primary-controller" ? 1 : 0
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
      "sudo -E -S /bin/bash /tmp/kubernetes-${var.kubernetes_type}.sh ${var.kubernetes_api_endpoint}:${var.kubernetes_api_port} ${local.vm_ip_address}:${var.kubernetes_api_port} ${random_password.certificate_key.result}"
    ]
  }

  depends_on = [
    null_resource.custom_ip_address
  ]
}