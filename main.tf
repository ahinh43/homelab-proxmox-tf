# Note that bulk creating all the nodes at once brings a problem in regards to the timing of a VM's creation
# and the assignment of a DHCP IP. A VM may accidentally target a DHCP IP that is assigned to the unintended target
# and provision the wrong machine with the wrong labels and taints (i.e making a worker node a control plane node)
# I haven't figured out a way around this yet, but for now its best to just make each node 1 by 1 to be safe.

module "pihole_dns_server_2" {
  source                    = "./modules/standard-vms/lxc-container"
  name                      = "pihole02"
  target_node               = "shizuru"
  clone_storage             = "local"
  template_vmid             = "109"
  ssh_private_key           = var.ssh_private_key
  ip_address                = "10.1.1.31"
  cpu_cores                 = 1
  memory                    = 256
  root_disk_size            = 12
  create_dns_record         = false
  run_standard_provisioning = false
}

module "captain_minecraft_vm" {
  source                    = "./modules/standard-vms/lxc-container"
  name                      = "cap10mc"
  target_node               = "shizuru"
  clone_storage             = "local-lvm"
  template_vmid             = "106"
  ssh_private_key           = var.ssh_private_key
  ip_address                = "10.1.1.32"
  cpu_cores                 = 2
  memory                    = 4096
  root_disk_size            = 16
  cloudflare_zone_id        = var.cloudflare_zone_id
  run_standard_provisioning = false
}

module "aqua" {
  source                    = "./modules/standard-vms/lxc-container"
  name                      = "aqua"
  target_node               = "shizuru"
  clone_storage             = "local"
  template_vmid             = "110"
  ssh_private_key           = var.ssh_private_key
  ip_address                = "10.1.1.16"
  cpu_cores                 = 1
  memory                    = 2048
  root_disk_size            = 12
  create_dns_record         = false
  run_standard_provisioning = false
}

module "artemis" {
  source                    = "./modules/standard-vms/lxc-container"
  name                      = "artemis"
  target_node               = "shizuru"
  clone_storage             = "local"
  template_vmid             = "101"
  ssh_private_key           = var.ssh_private_key
  ip_address                = "10.1.1.19"
  cpu_cores                 = 1
  memory                    = 2048
  root_disk_size            = 12
  create_dns_record         = false
  run_standard_provisioning = true
}


module "minio" {
  source             = "./modules/standard-vms/lxc-container"
  name               = "minio"
  target_node        = "shizuru"
  clone_storage      = "local"
  template_vmid      = "101"
  ssh_private_key    = var.ssh_private_key
  ip_address         = "10.1.1.17"
  cpu_cores          = 2
  memory             = 4096
  root_disk_size     = 8
  cloudflare_zone_id = var.cloudflare_zone_id
}
