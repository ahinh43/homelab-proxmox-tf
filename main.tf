# module "kube_controller_primary" {
#   source          = "./modules/kubernetes-vms"
#   vm_name         = "kubecontroller01"
#   target_node     = "shizuru"
#   ssh_private_key = var.ssh_private_key
#   kubernetes_type = "primary-controller"
# }
module "nikkos_pizza_server" {
  source                   = "./modules/standard-vms/lxc-container"
  name                     = "nikkocraft"
  target_node              = "shizuru"
  clone_storage            = "local-lvm"
  ssh_private_key          = var.ssh_private_key
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