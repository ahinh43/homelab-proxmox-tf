variable "name" {
  description = "Name of the VM. Required"
  type        = string
}

variable "target_node" {
  description = "Name of the cluster node to launch the VM into. Required."
  type        = string
}

variable "template_vmid" {
  description = "VMID to clone as a template. Defaults to 9000 for the Debian VM template. The template must be in a datastore accessible to the proxmox target node."
  type        = string
  default     = "9000"
}

variable "clone_storage" {
  description = "Name of the target storage to clone the VM into. Defaults to 'pve'"
  type        = string
  default     = "pve"
}

variable "memory" {
  description = "The amount of memory in MB to grant the VM. Defaults to 1024MB"
  type        = number
  default     = 1024
}

variable "cpu_cores" {
  description = "Amount of CPU cores per socket to grant the VM. Defaults to 1"
  type        = number
  default     = 1
}

variable "ssh_private_key" {
  description = "SSH private key string to connect to the VMs. Must match the key baked into the template. Required"
  sensitive   = true
  type        = string
}

variable "root_disk_size" {
  description = "Amount of Size in GB (defined as #G) to give the root volume. Defaults to 10G"
  type        = number
  default     = 10
}

variable "ip_address" {
  description = "The IP address of the VM. Required for the provisioner to work"
  type        = string
}

variable "gateway_address" {
  description = "The gateway address of the VM. Required for the provisioner to work"
  type        = string
}

variable "dns_servers" {
  description = "List of DNS servers to use on the VM. Defaults to 1.1.1.1 and 8.8.8.8 for public DNS servers"
  type = list(string)
  default = [
    "1.1.1.1",
    "8.8.8.8"
  ]
}

variable "minecraft_server_type" {
  description = "Common server types to install a minecraft server of. Can be vanilla or forge (for modded servers). Defaults to vanilla"
  type        = string
  default     = "vanilla"
}

variable "resource_pool_id" {
  description = "The resource pool ID to store the VMs in. Defaults to vm-general"
  type        = string
  default     = "vm-general"
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


variable "cloudinit_datastore_id" {
  description = "Name of the datastore to place the cloudinit disk in. Defaults to pve"
  type        = string
  default     = "pve"
}

variable "cloudinit_disk_interface" {
  description = "Name of the cloud-init disk interface to place the disk in. Defaults to ide2"
  type        = string
  default     = "ide2"
}

variable "cloudinit_configuration" {
  description = "A yaml block representing a cloud-init userdata config to pass to the VM."
  type        = string
  default     = null
}

variable "use_full_clone" {
  description = "Set to true to perform a full clone of the VM, which makes it a complete standalone VM. Set to false to do a linked clone."
  type        = bool
  default     = false
}
