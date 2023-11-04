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
  cloudflare_zone_id = var.cloudflare_zone_id
}

# Note that bulk creating all the nodes at once brings a problem in regards to the timing of a VM's creation
# and the assignment of a DHCP IP. A VM may accidentally target a DHCP IP that is assigned to the unintended target
# and provision the wrong machine with the wrong labels and taints (i.e making a worker node a control plane node)
# I haven't figured out a way around this yet, but for now its best to just make each node 1 by 1 to be safe.
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
  cloudflare_zone_id = var.cloudflare_zone_id
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
  cloudflare_zone_id = var.cloudflare_zone_id
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
  cloudflare_zone_id = var.cloudflare_zone_id
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
  create_dns_record = false
}

module "captain_minecraft_vm" {
  source          = "./modules/standard-vms/lxc-container"
  name            = "cap10mc"
  target_node     = "shizuru"
  clone_storage   = "data"
  template_vmid   = "106"
  ssh_private_key = var.ssh_private_key
  ip_address      = "10.1.1.32"
  cpu_cores       = 2
  memory          = 4096
  root_disk_size  = 16
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "ark_survival_ascended" {
  source          = "./modules/standard-vms/lxc-container"
  name            = "dinos"
  target_node     = "shizuru"
  clone_storage   = "data"
  template_vmid   = "106"
  ssh_private_key = var.ssh_private_key
  ip_address      = "10.1.1.34"
  cpu_cores       = 2
  memory          = 4096
  root_disk_size  = 32
  cloudflare_zone_id = var.cloudflare_zone_id
}

# module "lab_vm_1" {
#   source          = "./modules/standard-vms/lxc-container"
#   name            = "labvm1"
#   target_node     = "shizuru"
#   clone_storage   = "data"
#   template_vmid   = "106"
#   ssh_private_key = var.ssh_private_key
#   ip_address      = "10.1.1.33"
#   cpu_cores       = 2
#   memory          = 1024
#   root_disk_size  = 16
#   cloudflare_zone_id = var.cloudflare_zone_id
# }

# module "lab_vm_2" {
#   source          = "./modules/standard-vms/lxc-container"
#   name            = "labvm2"
#   target_node     = "shizuru"
#   clone_storage   = "data"
#   template_vmid   = "106"
#   ssh_private_key = var.ssh_private_key
#   ip_address      = "10.1.1.34"
#   cpu_cores       = 2
#   memory          = 1024
#   root_disk_size  = 16
#   cloudflare_zone_id = var.cloudflare_zone_id
# }