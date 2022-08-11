variable "vm_name" {
  description = "Name of the VM. Required"
  type        = string
}

variable "target_node" {
  description = "Name of the cluster node to launch the VM into. Required."
  type        = string
}

variable "template_name" {
  description = "Name of the VM template to clone from. Defaults to flatcar-template-current"
  type        = string
  default     = "flatcar-template-current"
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
  type = string
}

variable "vm_subnet_cidr" {
  description = "Cidr number for the IP address mask. Defaults to 24"
  type = string
  default = "24"
}

variable "vm_gateway_ip" {
  description = "Gateway IP address. Defualts to 10.1.1.1"
  type = string
  default = "10.1.1.1"
}

variable "vm_primary_dns_server" {
  description = "Primary DNS server for the VM to rely on. Defaults to 10.29.165.55"
  type = string
  default = "10.29.165.55"
}

variable "vm_secondary_dns_server" {
  description = "Secondary DNS server for the VM to rely on. Defaults to 10.1.1.31"
  type = string
  default = "10.1.1.31"
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

variable "kubernetes_api_endpoint" {
  description = "API endpoint to join/create the Kubernetes cluster on. Defaults to kube.adahinh.net"
  type = string
  default = "kube.adahinh.net"
}

variable "kubernetes_api_port" {
  description = "API port to reference the kubernetes cluster. Defaults to 6443"
  type = string
  default = "6443"
}

variable "additional_disk_configurations" {
  description = "List of objects containing disk configurations."
  type = list(object({
    storage_name = string
    size         = string
  }))
  default = null
}