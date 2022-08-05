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
  description = "Role of the new Kubernetes VM. Either worker or controller works. Required."
  type        = string
}