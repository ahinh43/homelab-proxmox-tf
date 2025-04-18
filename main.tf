# Note that bulk creating all the nodes at once brings a problem in regards to the timing of a VM's creation
# and the assignment of a DHCP IP. A VM may accidentally target a DHCP IP that is assigned to the unintended target
# and provision the wrong machine with the wrong labels and taints (i.e making a worker node a control plane node)
# I haven't figured out a way around this yet, but for now its best to just make each node 1 by 1 to be safe.

# module "pihole_dns_server_2" {
#   source                    = "./modules/standard-vms/lxc-container"
#   name                      = "pihole02"
#   target_node               = "shizuru"
#   clone_storage             = "local"
#   template_vmid             = "109"
#   ssh_private_key           = var.ssh_private_key
#   ip_address                = "10.1.1.31"
#   cpu_cores                 = 1
#   memory                    = 256
#   root_disk_size            = 12
#   create_dns_record         = false
#   run_standard_provisioning = false
# }

module "minio" {
  source             = "./modules/standard-vms/lxc-container"
  name               = "minio"
  target_node        = "nayu"
  clone_storage      = "pve"
  template_vmid      = "101"
  ssh_private_key    = var.ssh_private_key
  ip_address         = "10.1.1.17"
  cpu_cores          = 2
  memory             = 4096
  root_disk_size     = 100
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "ark_ascended" {
  source                  = "./modules/standard-vms/debian-vm"
  name                    = "ark-ascended"
  target_node             = "nia"
  clone_storage           = "local-lvm"
  ip_address              = "10.1.1.30"
  gateway_address         = "10.1.1.1"
  cpu_cores               = 8
  memory                  = (16 * 1024)
  cloudinit_configuration = file("./vm_userdata/ark-ascended.yaml")
  create_dns_record       = true
  cloudflare_zone_id      = var.cloudflare_zone_id
}

module "palworld_1" {
  source                  = "./modules/standard-vms/debian-vm"
  name                    = "palworld-1"
  target_node             = "shizuru"
  clone_storage           = "local-lvm"
  ip_address              = "10.1.1.32"
  gateway_address         = "10.1.1.1"
  cpu_cores               = 6
  memory                  = (16 * 1024)
  cloudinit_configuration = file("./vm_userdata/palworld.yaml")
  create_dns_record       = true
  cloudflare_zone_id      = var.cloudflare_zone_id
}
module "cap10mc" {
  source                  = "./modules/standard-vms/debian-vm"
  name                    = "cap10mc"
  target_node             = "shizuru"
  clone_storage           = "local-lvm"
  ip_address              = "10.1.1.36"
  gateway_address         = "10.1.1.1"
  cpu_cores               = 4
  memory                  = (8 * 1024)
  cloudinit_configuration = file("./vm_userdata/minecraft.yaml")
  create_dns_record       = true
  cloudflare_zone_id      = var.cloudflare_zone_id
}