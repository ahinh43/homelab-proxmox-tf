locals {
  vm_ip_address           = var.vm_ip_address
  kubernetes_api_endpoint = "${var.kubernetes_api_endpoint_name}.${var.kubernetes_api_endpoint_domain}"
  make_controller_worker  = var.make_controller_worker ? "yes" : "no"
  mount_longhorn_drive    = var.kubernetes_longhorn_mount_drive_passthrough != null ? var.kubernetes_longhorn_mount_drive_disk_name : ""
}

resource "proxmox_virtual_environment_vm" "main" {
  name      = var.vm_name
  node_name = var.target_node
  pool_id   = var.resource_pool_id

  clone {
    vm_id = var.template_id
    full  = var.full_clone
  }
  cpu {
    sockets = var.vm_cpu_sockets
    cores   = var.vm_cpu_cores
    type    = "host"
  }
  memory {
    dedicated = var.vm_memory
  }
  agent {
    enabled = var.enable_agent
  }

  on_boot = true

  network_device {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # The first disk block configures the root disk the OS is installed on. Any disk configurations beyond that is added
  # as an additional disk to the VM
  dynamic "disk" {
    for_each = var.additional_disk_configurations != null ? var.additional_disk_configurations : []
    content {
      interface         = disk.value["interface"]
      datastore_id      = disk.value["storage_name"]
      size              = disk.value["size"]
      path_in_datastore = disk.value["path_in_datastore"]
    }
  }

  reboot = false
}

# Changes the VM's IP address from the randomly assigned DHCP address to the desired IP address
# passed in this module. This is generally needed for DNS to properly work
resource "null_resource" "custom_ip_address" {
  triggers = {
    server = local.vm_ip_address
    vm_id  = proxmox_virtual_environment_vm.main.vm_id
  }

  connection {
    type        = "ssh"
    user        = "core"
    private_key = var.ssh_private_key
    host        = one(proxmox_virtual_environment_vm.main.ipv4_addresses[1])
  }
  provisioner "file" {
    source      = "${path.module}/provisioning/flatcar-set-custom-ip.sh"
    destination = "/tmp/flatcar-set-custom-ip.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/flatcar-set-custom-ip.sh ${var.vm_ip_address} ${var.vm_subnet_cidr} ${var.vm_gateway_ip} ${var.vm_primary_dns_server} ${var.vm_secondary_dns_server}",
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
    set -x
    VER=$(curl -fsSL https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt | grep FLATCAR_VERSION= | cut -d = -f 2)
    for i in $(seq 1 3); do [ $i -gt 1 ] && sleep 3; ssh -o ConnectTimeout=5 core@${one(proxmox_virtual_environment_vm.main.ipv4_addresses[1])} "sudo flatcar-update --to-version $VER" && s=0 && break || s=$?; done; (exit $s)
    ssh -o ConnectTimeout=5 core@${one(proxmox_virtual_environment_vm.main.ipv4_addresses[1])} '(sleep 2; sudo reboot)&'; sleep 3
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
    proxmox_virtual_environment_vm.main
  ]
}


data "template_file" "controller" {
  count    = (var.kubernetes_type == "controller" && var.kubernetes_cluster_token != null) ? 1 : 0
  template = file("${path.module}/provisioning/kubeadm-templates/join-controller.yaml.tpl")
  vars = {
    kubernetes_cluster_endpoint           = "${local.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
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
    kubernetes_cluster_endpoint    = "${local.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
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
    vm_id           = proxmox_virtual_environment_vm.main.vm_id
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
      "sudo -E -S /bin/bash /tmp/kubernetes-${self.triggers.kubernetes_type}.sh ${local.make_controller_worker} ${local.mount_longhorn_drive}"
    ]
  }

  # When destroying the VM, offboard the node from the Kubernetes cluster first before destroying it in Proxmox
  # If destroying the entire cluster, just comment this block out to avoid being stuck on waiting for the cluster
  # to respond
  provisioner "local-exec" {
    command = <<EOT
      kubectl drain node ${self.triggers.vm_name}.${self.triggers.vm_domain} --ignore-daemonsets --delete-local-data
      kubectl delete node ${self.triggers.vm_name}.${self.triggers.vm_domain} --force
    EOT
    when    = destroy
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash printf '%s' 'y' | kubeadm reset"
    ]
    when = destroy
  }

  depends_on = [proxmox_virtual_environment_vm.main]
}

resource "random_string" "kubeadm_token_1" {
  count   = (var.kubernetes_type == "primary-controller" && var.kubernetes_cluster_token == null) ? 2 : 0
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "kubeadm_token_2" {
  count   = (var.kubernetes_type == "primary-controller" && var.kubernetes_cluster_token == null) ? 2 : 0
  length  = 16
  special = false
  upper   = false
}

data "template_file" "primary_controller" {
  count    = (var.kubernetes_type == "primary-controller" && var.kubernetes_cluster_token == null) ? 1 : 0
  template = file("${path.module}/provisioning/kubeadm-templates/primary-controller-kubeadm-config.yaml.tpl")
  vars = {
    kubeadm_token_1                     = "${random_string.kubeadm_token_1[0].result}.${random_string.kubeadm_token_2[0].result}"
    kubeadm_token_2                     = "${random_string.kubeadm_token_1[1].result}.${random_string.kubeadm_token_2[1].result}"
    kubernetes_controller_local_address = local.vm_ip_address
    kubernetes_controller_local_port    = var.kubernetes_api_port
    kubernetes_api_endpoint             = "${local.kubernetes_api_endpoint}:${var.kubernetes_api_port}"
    kubernetes_pod_subnet               = var.kubernetes_pod_subnet
    kubernetes_service_subnet           = var.kubernetes_service_subnet
  }
}

data "template_file" "cilium_values" {
  count    = (var.kubernetes_type == "primary-controller" && var.kubernetes_cluster_token == null) ? 1 : 0
  template = file("${path.module}/provisioning/kubeadm-templates/cilium-values.yaml.tpl")
  vars = {
    kubernetes_pod_subnet            = jsonencode([var.kubernetes_pod_subnet])
    kubernetes_cluster_name          = var.kubernetes_api_endpoint_name
    kubernetes_cluster_id            = var.kubernetes_cilium_cluster_id
    kubernetes_api_server_ip         = var.kubernetes_cluster_vip
    kubernetes_controller_local_port = var.kubernetes_api_port
  }
}


resource "null_resource" "kube_primary_controller_provision" {
  count = var.kubernetes_type == "primary-controller" ? 1 : 0
  triggers = {
    server = local.vm_ip_address
    vm_id  = proxmox_virtual_environment_vm.main.vm_id
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

  provisioner "file" {
    content     = data.template_file.cilium_values[0].rendered
    destination = "/home/core/cilium-values.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E -S /bin/bash /tmp/kubernetes-${var.kubernetes_type}.sh ${var.kubernetes_cluster_vip} ${var.kubernetes_api_endpoint_name} ${local.make_controller_worker}"
    ]
  }

  depends_on = [
    null_resource.custom_ip_address
  ]
}


## DNS records, if enabled

module "kubernetes_api_endpoint_record" {
  count         = (var.kubernetes_type == "primary-controller" && var.create_dns_record) ? 1 : 0
  source        = "../cloudflare_dns_record"
  zone_id       = var.cloudflare_zone_id
  record_name   = "${var.kubernetes_api_endpoint_name}.labs"
  record_target = var.kubernetes_cluster_vip
}

module "vm_dns_record" {
  count         = var.create_dns_record ? 1 : 0
  source        = "../cloudflare_dns_record"
  zone_id       = var.cloudflare_zone_id
  record_name   = "${var.vm_name}.labs"
  record_target = local.vm_ip_address
}