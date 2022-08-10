module "kube_controller_primary" {
  source          = "./modules/kubernetes-vms"
  vm_name         = "kubecont01"
  target_node     = "shizuru"
  ssh_private_key = var.ssh_private_key
  kubernetes_type = "primary-controller"
}


module "nikkos_pizza_server" {
  source                   = "./modules/standard-vms/lxc-container"
  name                     = "nikkocraft"
  target_node              = "shizuru"
  clone_storage            = "local-lvm"
  ssh_private_key          = var.ssh_private_key
  template_vmid            = "112"
  ip_address               = "10.1.1.12"
  cpu_cores                = 4
  memory                   = 8192
  root_disk_size           = 40
  provision_minecraft      = true
  minecraft_server_type    = "forge"
  minecraft_server_version = "1.12.2"
  minecraft_jre_version    = "8"
  minecraft_jre_min_mem    = "2"
  minecraft_jre_max_mem    = "7"
}

moved {
  from = module.nikkos_pizza_server.null_resource.minecraft
  to = module.nikkos_pizza_server.null_resource.minecraft[0]
}

module "pihole_dns_server_2" {
  source                   = "./modules/standard-vms/lxc-container"
  name                     = "pihole02"
  target_node              = "grace"
  clone_storage            = "data"
  template_vmid            = "109"
  ssh_private_key          = var.ssh_private_key
  ip_address               = "10.1.1.31"
  cpu_cores                = 1
  memory                   = 256
  root_disk_size           = 12
}

module "haproxy_2" {
  source                   = "./modules/standard-vms/lxc-container"
  name                     = "haproxy02"
  target_node              = "shizuru"
  clone_storage            = "local-lvm"
  template_vmid            = "110"
  ssh_private_key          = var.ssh_private_key
  ip_address               = "10.1.1.11"
  os_family                = "alpine"
  cpu_cores                = 2
  memory                   = 1024
  root_disk_size           = 12
}