module "kube_controller_primary" {
  source          = "./modules/kubernetes-vms"
  vm_name         = "kubecont01"
  vm_ip_address   = "10.1.1.26"
  target_node     = "shizuru"
  ssh_private_key = var.ssh_private_key
  kubernetes_type = "primary-controller"
  kubernetes_cluster_vip = "10.1.1.6"
  additional_disk_configurations = [
    {
      size = "40G"
      storage_name = "local-lvm"
    }
  ]
}

module "kube_controller_2" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubecont02"
  vm_ip_address                      = "10.1.1.27"
  target_node                        = "grace"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "controller"
  kubernetes_cluster_token           = var.k8s_cluster_token
  kubernetes_cluster_certificate_key = var.k8s_certificate_key
  kubernetes_cacert_hash             = var.k8s_cacert_hash
  additional_disk_configurations = [ 
    {
      size = "40G"
      storage_name = "grace-lvm"
    }
  ]
}

module "kube_controller_3" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubecont03"
  vm_ip_address                      = "10.1.1.28"
  target_node                        = "nia"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "controller"
  kubernetes_cluster_token           = var.k8s_cluster_token
  kubernetes_cluster_certificate_key = var.k8s_certificate_key
  kubernetes_cacert_hash             = var.k8s_cacert_hash
  additional_disk_configurations = [ 
    {
      size = "40G"
      storage_name = "local-lvm-thin"
    }
  ]
}

module "kube_worker_1" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubework01"
  vm_ip_address                      = "10.1.1.13"
  target_node                        = "shizuru"
  vm_cpu_sockets                     = 4
  vm_memory                          = 16384
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_token
  kubernetes_cluster_certificate_key = var.k8s_certificate_key
  kubernetes_cacert_hash             = var.k8s_cacert_hash
  additional_disk_configurations = [
    {
      size = "100G"
      storage_name = "local-lvm"
    }
  ]
}

module "kube_worker_2" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubework02"
  vm_ip_address                      = "10.1.1.14"
  vm_cpu_sockets                     = 4
  vm_memory                          = 8192
  target_node                        = "grace"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_token
  kubernetes_cluster_certificate_key = var.k8s_certificate_key
  kubernetes_cacert_hash             = var.k8s_cacert_hash
  additional_disk_configurations = [ 
    {
      size = "100G"
      storage_name = "grace-lvm"
    }
  ]
}
module "kube_worker_3" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubework03"
  vm_ip_address                      = "10.1.1.15"
  vm_cpu_sockets                     = 4
  vm_memory                          = 8192
  target_node                        = "nia"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_token
  kubernetes_cluster_certificate_key = var.k8s_certificate_key
  kubernetes_cacert_hash             = var.k8s_cacert_hash
  additional_disk_configurations = [ 
    {
      size = "100G"
      storage_name = "local-lvm-thin"
    }
  ]
}

module "pihole_dns_server_2" {
  source          = "./modules/standard-vms/lxc-container"
  name            = "pihole02"
  target_node     = "grace"
  clone_storage   = "data"
  template_vmid   = "109"
  ssh_private_key = var.ssh_private_key
  ip_address      = "10.1.1.31"
  cpu_cores       = 1
  memory          = 256
  root_disk_size  = 12
}

module "aqua_server" {
  source          = "./modules/standard-vms/lxc-container"
  name            = "aqua"
  target_node     = "shizuru"
  clone_storage   = "local-lvm"
  template_vmid   = "110"
  os_family       = "alpine"
  ssh_private_key = var.ssh_private_key
  ip_address      = "10.1.1.32"
  cpu_cores       = 1
  memory          = 2048
  root_disk_size  = 12
}