# module "kube_controller_primary" {
#   source          = "./modules/kubernetes-vms"
#   vm_name         = "kubecontroller01"
#   target_node     = "shizuru"
#   ssh_private_key = var.ssh_private_key
#   kubernetes_type = "primary-controller"
# }

module "test_lxc" {
  source          = "./modules/standard-vms/lxc-container"
  name            = "testlxc"
  target_node     = "shizuru"
  clone_storage   = "local-lvm"
  ssh_private_key = var.ssh_private_key
  ip_address      = "10.1.1.98"
}

module "test_vanilla_minecraft" {
  source                   = "./modules/standard-vms/lxc-container"
  name                     = "testminecraft"
  target_node              = "shizuru"
  clone_storage            = "local-lvm"
  ssh_private_key          = var.ssh_private_key
  ip_address               = "10.1.1.99"
  cpu_cores                = 2
  memory                   = 4096
  root_disk_size           = 20
  provision_minecraft      = true
  minecraft_server_type    = "vanilla"
  minecraft_server_version = "1.19.2"
}