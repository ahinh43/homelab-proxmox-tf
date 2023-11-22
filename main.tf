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

module "kube_controller_2" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubecont02"
  vm_ip_address                      = "10.1.1.27"
  target_node                        = "grace"
  template_id                        = 111
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "controller"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [
    {
      size         = 40
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "kube_controller_3" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubecont03"
  vm_ip_address                      = "10.1.1.28"
  target_node                        = "nia"
  template_id                        = 113
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "controller"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [
    {
      size         = 40
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "kube_worker_1" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubework01"
  vm_ip_address                      = "10.1.1.13"
  target_node                        = "shizuru"
  vm_cpu_sockets                     = 1
  vm_cpu_cores                       = 6
  vm_memory                          = 16384
  template_id                        = 103
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [
    {
      size = 100
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "kube_worker_2" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubework02"
  vm_ip_address                      = "10.1.1.14"
  vm_cpu_sockets                     = 1
  vm_cpu_cores                       = 10
  vm_memory                          = 16384
  template_id                        = 111
  target_node                        = "grace"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [ 
    {
      size = 100
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "kube_worker_3" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kubework03"
  vm_ip_address                      = "10.1.1.15"
  vm_cpu_sockets                     = 1
  vm_cpu_cores                       = 10
  vm_memory                          = 16384
  template_id                        = 113
  target_node                        = "nia"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [ 
    {
      size = 100
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

# module "kube2_controller_primary" {
#   source                       = "./modules/kubernetes-vms"
#   vm_name                      = "kube2cont01"
#   vm_ip_address                = "10.1.1.40"
#   vm_cpu_sockets               = 1
#   vm_cpu_cores                 = 6
#   vm_memory                    = 14336
#   target_node                  = "tear"
#   template_id                  = 106
#   ssh_private_key              = var.ssh_private_key
#   kubernetes_type              = "primary-controller"
#   kubernetes_cluster_vip       = "10.1.1.11"
#   kubernetes_pod_subnet        = "10.245.0.0/16"
#   kubernetes_service_subnet    = "10.97.0.0/16"
#   kubernetes_api_endpoint_name = "kube2"
#   make_controller_worker       = true
#   additional_disk_configurations = [
#     {
#       size         = 100
#       storage_name = "local-lvm"
#     }
#   ]
#   cloudflare_zone_id = var.cloudflare_zone_id
# }

# module "kube2_controller_2" {
#   source                             = "./modules/kubernetes-vms"
#   vm_name                            = "kube2cont02"
#   vm_ip_address                      = "10.1.1.41"
#   target_node                        = "lefi"
#   template_id                        = 109
#   vm_cpu_sockets                     = 1
#   vm_cpu_cores                       = 6
#   vm_memory                          = 14336
#   ssh_private_key                    = var.ssh_private_key
#   kubernetes_api_endpoint_name       = "kube2"
#   kubernetes_type                    = "controller"
#   kubernetes_cluster_token           = var.k8s_cluster_information[1].cluster_token
#   kubernetes_cluster_certificate_key = var.k8s_cluster_information[1].certificate_key
#   kubernetes_cacert_hash             = var.k8s_cluster_information[1].cacert_hash
#   additional_disk_configurations = [
#     {
#       size         = 100
#       storage_name = "local-lvm"
#     }
#   ]
#   make_controller_worker = true
#   cloudflare_zone_id     = var.cloudflare_zone_id
# }

# module "kube2_controller_3" {
#   source                             = "./modules/kubernetes-vms"
#   vm_name                            = "kube2cont03"
#   vm_ip_address                      = "10.1.1.42"
#   target_node                        = "vern"
#   template_id                        = 112
#   vm_cpu_sockets                     = 1
#   vm_cpu_cores                       = 6
#   vm_memory                          = 14336
#   ssh_private_key                    = var.ssh_private_key
#   kubernetes_api_endpoint_name       = "kube2"
#   kubernetes_type                    = "controller"
#   kubernetes_cluster_token           = var.k8s_cluster_information[1].cluster_token
#   kubernetes_cluster_certificate_key = var.k8s_cluster_information[1].certificate_key
#   kubernetes_cacert_hash             = var.k8s_cluster_information[1].cacert_hash
#   additional_disk_configurations = [
#     {
#       size         = 100
#       storage_name = "local-lvm"
#     }
#   ]
#   make_controller_worker = true
#   cloudflare_zone_id     = var.cloudflare_zone_id
# }




# Note that bulk creating all the nodes at once brings a problem in regards to the timing of a VM's creation
# and the assignment of a DHCP IP. A VM may accidentally target a DHCP IP that is assigned to the unintended target
# and provision the wrong machine with the wrong labels and taints (i.e making a worker node a control plane node)
# I haven't figured out a way around this yet, but for now its best to just make each node 1 by 1 to be safe.

module "pihole_dns_server_2" {
  source            = "./modules/standard-vms/lxc-container"
  name              = "pihole02"
  target_node       = "grace"
  clone_storage     = "local"
  template_vmid     = "109"
  ssh_private_key   = var.ssh_private_key
  ip_address        = "10.1.1.31"
  cpu_cores         = 1
  memory            = 256
  root_disk_size    = 12
  create_dns_record = false
}

module "captain_minecraft_vm" {
  source             = "./modules/standard-vms/lxc-container"
  name               = "cap10mc"
  target_node        = "grace"
  clone_storage      = "local-lvm"
  template_vmid      = "106"
  ssh_private_key    = var.ssh_private_key
  ip_address         = "10.1.1.32"
  cpu_cores          = 2
  memory             = 4096
  root_disk_size     = 16
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "aqua" {
  source            = "./modules/standard-vms/lxc-container"
  name              = "aqua"
  target_node       = "shizuru"
  clone_storage     = "local"
  template_vmid     = "110"
  ssh_private_key   = var.ssh_private_key
  ip_address        = "10.1.1.16"
  cpu_cores         = 1
  memory            = 2048
  root_disk_size    = 12
  create_dns_record = false
}