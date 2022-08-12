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
  hotplug     = "network,disk,usb"
  onboot      = true

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
      storage = disk.value["storage_name"]
      size    = disk.value["size"]
    }
  }

  automatic_reboot = false

  lifecycle {
    ignore_changes = [
      ipconfig0
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
    set -x
    ssh -o ConnectTimeout=5 core@${proxmox_vm_qemu.main.default_ipv4_address} '(sleep 2; sudo reboot)&'; sleep 3
    until ssh core@${local.vm_ip_address} -o ConnectTimeout=2 'true 2> /dev/null'
    do
      echo "Waiting for the server to come back up..."
      sleep 2
    done
    EOT
  }

  provisioner "local-exec" {
    command = "echo 'Sleeping 10 seconds to let the server get its network stuff settled...'; sleep 10"
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
    kubernetes_controller_local_address   = local.vm_ip_address
    kubernetes_controller_local_port      = var.kubernetes_api_port
    kubernetes_controller_certificate_key = var.kubernetes_cluster_certificate_key
  }
}

data "template_file" "worker" {
  count    = (var.kubernetes_type == "worker" && var.kubernetes_cluster_token != null) ? 1 : 0
  template = file("${path.module}/provisioning/kubeadm-templates/join-worker.yaml.tpl")
  vars = {
    kubernetes_cluster_endpoint    = "${var.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
    kubernetes_cluster_token       = var.kubernetes_cluster_token
    kubernetes_cluster_cacert_hash = var.kubernetes_cacert_hash
  }
}

resource "null_resource" "kube_join_provision" {
  count = (var.kubernetes_type == "controller" || var.kubernetes_type == "worker") ? 1 : 0
  triggers = {
    server          = var.vm_ip_address
    vm_name         = var.vm_name
    vm_ip_address   = local.vm_ip_address
    vm_domain       = var.vm_domain
    ssh_private_key = var.ssh_private_key
    kubernetes_type = var.kubernetes_type
  }

  connection {
    type        = "ssh"
    user        = "core"
    private_key = self.triggers.ssh_private_key
    host        = self.triggers.vm_ip_address
  }

  provisioner "file" {
    source      = "${path.module}/provisioning/kubernetes-${self.triggers.kubernetes_type}.sh"
    destination = "/tmp/kubernetes-${self.triggers.kubernetes_type}.sh"
  }

  provisioner "file" {
    content     = var.kubernetes_type == "controller" ? data.template_file.controller[0].rendered : data.template_file.worker[0].rendered
    destination = "/tmp/join-${self.triggers.kubernetes_type}.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /bin/hostnamectl set-hostname ${self.triggers.vm_name}.${self.triggers.vm_domain}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/kubernetes-${self.triggers.kubernetes_type}.sh"
    ]
  }

  # provisioner "local-exec" {
  #   command = <<EOT
  #     kubectl drain node ${self.triggers.vm_name}.${self.triggers.vm_domain} --ignore-daemonsets --delete-local-data
  #     kubectl delete node ${self.triggers.vm_name}.${self.triggers.vm_domain} --force
  #   EOT
  #   when    = destroy
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo -E -S /bin/bash printf '%s' 'y' | kubeadm reset"
  #   ]
  #   when = destroy
  # }

  depends_on = [
    null_resource.custom_ip_address
  ]
}

data "template_file" "primary_controller" {
  count    = (var.kubernetes_type == "primary-controller" && var.kubernetes_cluster_token == null) ? 1 : 0
  template = file("${path.module}/provisioning/kubeadm-templates/primary-controller-kubeadm-config.yaml.tpl")
  vars = {
    kubernetes_controller_local_address = local.vm_ip_address
    kubernetes_controller_local_port    = var.kubernetes_api_port
    kubernetes_api_endpoint             = "${var.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
  }
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
      "sudo /bin/hostnamectl set-hostname ${var.vm_name}.${var.vm_domain}"
    ]
  }
  provisioner "file" {
    content     = data.template_file.primary_controller[0].rendered
    destination = "/home/core/kubeadm-config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/kubernetes-${var.kubernetes_type}.sh ${var.kubernetes_cluster_vip}"
    ]
  }

  depends_on = [
    null_resource.custom_ip_address
  ]
}