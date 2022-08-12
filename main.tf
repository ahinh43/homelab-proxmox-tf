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
      size = "40G"
      storage_name = "local-lvm"
    },
    {
      size = "60G"
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
      size = "40G"
      storage_name = "grace-lvm"
    },
    {
      size = "60G"
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
      size = "40G"
      storage_name = "local-lvm-thin"
    },
    {
      size = "60G"
      storage_name = "local-lvm-thin"
    } 
  ]
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
  to   = module.nikkos_pizza_server.null_resource.minecraft[0]
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

module "haproxy_2" {
  source          = "./modules/standard-vms/lxc-container"
  name            = "haproxy02"
  target_node     = "shizuru"
  clone_storage   = "local-lvm"
  template_vmid   = "110"
  ssh_private_key = var.ssh_private_key
  ip_address      = "10.1.1.11"
  os_family       = "alpine"
  cpu_cores       = 2
  memory          = 1024
  root_disk_size  = 12
}