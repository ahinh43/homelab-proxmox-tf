
resource "proxmox_virtual_environment_file" "cloud_config" {
  count        = var.cloudinit_configuration != null ? 1 : 0
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    data      = var.cloudinit_configuration
    file_name = "cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "main" {
  name      = var.name
  node_name = var.target_node
  tags      = var.tags

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
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
    datastore_id = var.cloudinit_datastore_id
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
      network_device,
      ipv4_addresses,
      ipv6_addresses,
      network_interface_names,
      vga,
      initialization
    ]
  }

}

module "vm_dns_record" {
  count         = var.create_dns_record ? 1 : 0
  source        = "../../cloudflare_dns_record"
  zone_id       = var.cloudflare_zone_id
  record_name   = "${var.name}.labs"
  record_target = var.ip_address
}
