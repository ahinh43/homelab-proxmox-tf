module "kube_controller_primary" {
  source                 = "./modules/kubernetes-vms"
  vm_name                = "kubecont01"
  vm_ip_address          = "10.1.1.26"
  template_id            = 103
  target_node            = "shizuru"
  ssh_private_key        = var.ssh_private_key
  kubernetes_type        = "primary-controller"
  kubernetes_cluster_vip = "10.1.1.6"
  vm_memory              = 4096
  onepassword_token      = var.onepassword_token
  additional_disk_configurations = [
    {
      size         = 40
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}
