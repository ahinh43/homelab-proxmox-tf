variable "name" {
  description = "Name of the container. Required"
  type        = string
}

variable "target_node" {
  description = "Name of the cluster node to launch the container into. Required."
  type        = string
}

variable "template_vmid" {
  description = "VMID to clone as a template. Defaults to 112 for the Ubuntu 20.04 Container Template"
  type        = string
  default     = "112"
}

variable "clone_storage" {
  description = "Name of the target storage to clone the container into. Required"
  type        = string
}

variable "memory" {
  description = "The amount of memory in MB to grant the container. Defaults to 256MB"
  type        = number
  default     = 256
}

variable "cpu_cores" {
  description = "Amount of CPU cores per socket to grant the container. Defaults to 1"
  type        = number
  default     = 1
}

variable "ssh_private_key" {
  description = "SSH private key string to connect to the containers. Must match the key baked into the template. Required"
  sensitive   = true
  type        = string
}

variable "root_disk_size" {
  description = "Amount of Size in GB (defined as #G) to give the root volume. Defaults to 8G"
  type        = string
  default     = "8G"
}