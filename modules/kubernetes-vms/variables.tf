variable "vm_name" {
  description = "Name of the VM. Required"
  type        = string
}

variable "target_node" {
  description = "Name of the cluster node to launch the VM into. Required."
  type        = string
}

variable "template_id" {
  description = "The ID of the VM template to clone from when creating the VM. Required."
  type        = number
}

variable "vm_memory" {
  description = "The amount of memory in MB to grant the VM. Defaults to 4GB"
  type        = number
  default     = 4096
}

variable "vm_cpu_sockets" {
  description = "Amount of CPU sockets to grant the VM. CPU count is sockets * cores. Defaults to 2"
  type        = number
  default     = 2
}

variable "vm_cpu_cores" {
  description = "Amount of CPU cores per socket to grant the VM. CPU Count is sockets * cores. Defaults to 1."
  type        = number
  default     = 1
}

variable "vm_ip_address" {
  description = "IP address of the VM to set. Required due to needing to point Kubernetes properly"
  type        = string
}

variable "vm_subnet_cidr" {
  description = "Cidr number for the IP address mask. Defaults to 24"
  type        = string
  default     = "24"
}

variable "vm_gateway_ip" {
  description = "Gateway IP address. Defualts to 10.1.1.1"
  type        = string
  default     = "10.1.1.1"
}

variable "vm_primary_dns_server" {
  description = "Primary DNS server for the VM to rely on. Defaults to 10.29.165.55"
  type        = string
  default     = "10.29.165.55"
}

variable "vm_secondary_dns_server" {
  description = "Secondary DNS server for the VM to rely on. Defaults to 10.1.1.31"
  type        = string
  default     = "10.1.1.31"
}

variable "vm_domain" {
  description = "Domain name of the VM. Defaults to labs.ahinh.me"
  type        = string
  default     = "labs.ahinh.me"
}

variable "enable_agent" {
  description = "Enables the QEMU agent if set to true. Defaults to true"
  type        = bool
  default     = true
}

variable "ssh_private_key" {
  description = "SSH private key string to connect to the VMs. Must match the key baked into the template. Required"
  sensitive   = true
  type        = string
}

variable "kubernetes_type" {
  description = "Role of the new Kubernetes VM. use 'worker' for a worker node, 'controller' to join a new controller to the cluster, and 'primary-controller' to create an entirely new cluster"
  type        = string
}

variable "kubernetes_api_endpoint_name" {
  description = "API endpoint name to create the Kubernetes api endpoint on. Defaults to kube"
  type        = string
  default     = "kube"
}

variable "kubernetes_cilium_cluster_id" {
  description = "A unique ID number to identify the cluster for cilium clustermesh. Not used unless using Cilium clustermesh. Defaults to 100"
  type        = number
  default     = 100
}

variable "full_clone" {
  description = "Whether or not to do a full clone. Full clone completely removes any dependencies on the template, but is slower to create VMs and takes more space. Defaults to false for linked cloning."
  type        = bool
  default     = false
}

variable "resource_pool_id" {
  description = "The resource pool ID to store the containers in. Defaults to kubernetes-nodes"
  type        = string
  default     = "kubernetes-nodes"
}

variable "kubernetes_api_endpoint_domain" {
  description = "API endpoint domain name to create the endpoint with. Defaults to labs.ahinh.me"
  type        = string
  default     = "labs.ahinh.me"
}
variable "kubernetes_api_port" {
  description = "API port to reference the kubernetes cluster. Defaults to 6443"
  type        = string
  default     = "6443"
}

variable "kubernetes_longhorn_mount_drive_passthrough" {
  description = "Disk path/ID to pass a direct hard drive into a worker VM to mount as /var/lib/longhorn for PVCs. Should be `/dev/disk/by-id/xxxxx`"
  type        = string
  default     = null
}

variable "kubernetes_longhorn_mount_drive_disk_name" {
  description = "The disk name as it appears in the OS to mount for the longhorn directory. Defaults to `scsi-0QEMU_QEMU_HARDDISK_drive-scsi2` as the template comes with only 1 disk and the next is mounted on scsi2"
  type        = string
  default     = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi2"
}

variable "kubernetes_pod_subnet" {
  description = "The subnet to assign pods to in CIDR notation. Defaults to 10.244.0.0/16"
  type        = string
  default     = "10.244.0.0/16"
}

variable "kubernetes_service_subnet" {
  description = "The subnet to assign pods to in CIDR notation. Defaults to 10.96.0.0/16"
  type        = string
  default     = "10.96.0.0/16"
}

variable "additional_disk_configurations" {
  description = "List of objects containing disk configurations. First entry modifies the initial template disk"
  type = list(object({
    interface         = optional(string, "scsi0")
    storage_name      = string
    size              = number
    path_in_datastore = optional(string, null)
  }))
  default = null
}
variable "kubernetes_cluster_token" {
  description = "Cluster token for the Kubernetes node. Required if joining a node to the cluster. Tokens usually expire after 24 hours after a token generation"
  type        = string
  default     = null
}

variable "kubernetes_cluster_vip" {
  description = "VIP for the Kubernetes node. Only needed for the primary controller"
  type        = string
  default     = null
}

variable "kubernetes_cacert_hash" {
  description = "CA Cert hash for the Kubernetes node. Required if joining a node to the cluster"
  type        = string
  default     = null
}

variable "kubernetes_cluster_certificate_key" {
  description = "Cluster cert key used to add new controllers to the cluster"
  type        = string
  default     = null
}

variable "kubernetes_main_controller_ip" {
  description = "IP address of the primary controller used to configure the cluster. Required for joining new controllers"
  type        = string
  default     = null
}

variable "make_controller_worker" {
  description = "Set to true to remove the control plane taint on the node so regular workloads can be scheduled on it."
  type        = bool
  default     = false
}

variable "create_dns_record" {
  description = "Automatically create the DNS record for the new node. For the primary cluster, this will also create the kubernetes API endpoint record too. Defaults to true"
  type        = bool
  default     = true
}
variable "cloudflare_zone_id" {
  description = "The zone ID to configure the record in. Required if create_dns_record is true"
  type        = string
  default     = null
}

variable "cloudflare_dns_name_override" {
  description = "Name to override the DNS record name in cloudflare if provided. Defaults to null"
  type        = string
  default     = null
}