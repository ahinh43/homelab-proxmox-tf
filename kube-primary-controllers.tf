module "kube_controller_primary" {
  source                 = "./modules/kubernetes-vms"
  vm_name                = "kubecont01"
  vm_ip_address          = "10.1.1.26"
  template_id            = 103
  target_node            = "shizuru"
  ssh_private_key        = var.ssh_private_key
  kubernetes_type        = "primary-controller"
  kubernetes_cluster_vip = "10.1.1.6"
  additional_disk_configurations = [
    {
      size         = 40
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "kube2_controller_primary" {
  source                       = "./modules/kubernetes-vms"
  vm_name                      = "kube2cont01"
  vm_ip_address                = "10.1.1.40"
  vm_cpu_sockets               = 1
  vm_cpu_cores                 = 6
  vm_memory                    = 14336
  make_controller_worker       = true
  target_node                  = "tear"
  template_id                  = 106
  ssh_private_key              = var.ssh_private_key
  kubernetes_type              = "primary-controller"
  kubernetes_cluster_vip       = "10.1.1.11"
  kubernetes_pod_subnet        = "10.245.0.0/16"
  kubernetes_service_subnet    = "10.97.0.0/16"
  kubernetes_api_endpoint_name = "kube2"
  kubernetes_cilium_cluster_id = 200
  additional_disk_configurations = [
    {
      size         = 100
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}