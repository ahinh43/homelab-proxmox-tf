module "kube_controller_primary" {
  source          = "./modules/kubernetes-vms"
  vm_name         = "kubecontroller01"
  target_node     = "shizuru"
  ssh_private_key = var.ssh_private_key
  kubernetes_type = "primary-controller"
}

