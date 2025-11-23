
resource "proxmox_virtual_environment_file" "cloud_config" {
  count        = var.cloudinit_configuration != null ? 1 : 0
  content_type = "snippets"
  datastore_id = var.cloudinit_snippet_datastore_id
  node_name    = var.target_node

  source_raw {
    data      = var.cloudinit_configuration
    file_name = "cloud-config-${var.name}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "main" {
  name      = var.name
  node_name = var.target_node
  tags      = var.tags
  started   = true

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
    units = 1024
  }

  memory {
    dedicated = var.memory
  }

  clone {
    datastore_id = var.use_full_clone ? var.clone_storage : null
    vm_id        = var.template_vmid
    full         = var.use_full_clone
  }

  initialization {
    datastore_id = var.clone_storage
    ip_config {
      ipv4 {
        address = "${var.ip_address}${var.ip_subnet_cidr}"
        gateway = var.gateway_address
      }
    }
    dns {
      servers = var.dns_servers
    }

    user_data_file_id = var.cloudinit_configuration != null ? proxmox_virtual_environment_file.cloud_config[0].id : null
  }

  lifecycle {
    ignore_changes = [
      node_name,
      description,
      tags,
      pool_id,
      network_device,
      vga,
      initialization,
      started,
      clone,
      migrate,
      operating_system,
      serial_device,
      keyboard_layout,

    ]
  }

}

resource "proxmox_virtual_environment_pool_membership" "main" {
  count   = var.resource_pool_id != null ? 1 : 0
  pool_id = var.resource_pool_id
  vm_id   = proxmox_virtual_environment_vm.main.vm_id
}

module "vm_dns_record" {
  count         = var.create_dns_record ? 1 : 0
  source        = "../../cloudflare_dns_record"
  zone_id       = var.cloudflare_zone_id
  record_name   = "${var.name}.labs"
  record_target = var.ip_address
}
