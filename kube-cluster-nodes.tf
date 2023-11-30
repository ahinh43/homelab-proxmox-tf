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
  vm_memory                          = 24576
  template_id                        = 103
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [
    {
      size         = 100
      storage_name = "local-lvm"
      datastore_id = "local-lvm"
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
  vm_memory                          = 24576
  template_id                        = 111
  target_node                        = "grace"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [
    {
      size         = 100
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
  vm_memory                          = 24576
  template_id                        = 113
  target_node                        = "nia"
  ssh_private_key                    = var.ssh_private_key
  kubernetes_type                    = "worker"
  kubernetes_cluster_token           = var.k8s_cluster_information[0].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[0].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[0].cacert_hash
  additional_disk_configurations = [
    {
      size         = 100
      storage_name = "local-lvm"
    }
  ]
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "kube2_controller_2" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kube2cont02"
  vm_ip_address                      = "10.1.1.41"
  target_node                        = "lefi"
  template_id                        = 109
  vm_cpu_sockets                     = 1
  vm_cpu_cores                       = 6
  vm_memory                          = 14336
  ssh_private_key                    = var.ssh_private_key
  kubernetes_api_endpoint_name       = "kube2"
  kubernetes_type                    = "controller"
  kubernetes_cluster_token           = var.k8s_cluster_information[1].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[1].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[1].cacert_hash
  additional_disk_configurations = [
    {
      size         = 100
      storage_name = "local-lvm"
    }
  ]
  make_controller_worker = true
  cloudflare_zone_id     = var.cloudflare_zone_id
}

module "kube2_controller_3" {
  source                             = "./modules/kubernetes-vms"
  vm_name                            = "kube2cont03"
  vm_ip_address                      = "10.1.1.42"
  target_node                        = "vern"
  template_id                        = 112
  vm_cpu_sockets                     = 1
  vm_cpu_cores                       = 6
  vm_memory                          = 14336
  ssh_private_key                    = var.ssh_private_key
  kubernetes_api_endpoint_name       = "kube2"
  kubernetes_type                    = "controller"
  kubernetes_cluster_token           = var.k8s_cluster_information[1].cluster_token
  kubernetes_cluster_certificate_key = var.k8s_cluster_information[1].certificate_key
  kubernetes_cacert_hash             = var.k8s_cluster_information[1].cacert_hash
  additional_disk_configurations = [
    {
      size         = 100
      storage_name = "local-lvm"
    }
  ]
  make_controller_worker = true
  cloudflare_zone_id     = var.cloudflare_zone_id
}