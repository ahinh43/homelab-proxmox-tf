variable "name" {
  description = "Name of the container. Required"
  type        = string
}

variable "target_node" {
  description = "Name of the cluster node to launch the container into. Required."
  type        = string
}

variable "template_vmid" {
  description = "VMID to clone as a template. Defaults to 106 for the Ubuntu 22.04 Container Template"
  type        = string
  default     = "106"
}

variable "os_family" {
  description = "OS family to provision. Defaults to Ubuntu, but can also select 'alpine' for Alpine containers"
  type        = string
  default     = "ubuntu"
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
  type        = number
  default     = 8
}

variable "ip_address" {
  description = "The IP address of the container. Required for the provisioner to work"
  type        = string
}

variable "provision_minecraft" {
  description = "Whether or not to provision a minecraft server. Defaults to false"
  type        = bool
  default     = false
}


variable "run_standard_provisioning" {
  description = "Whether or not to run standard provisiong for the container. Defaults to true"
  type        = bool
  default     = true
}


variable "minecraft_server_type" {
  description = "Common server types to install a minecraft server of. Can be vanilla or forge (for modded servers). Defaults to vanilla"
  type        = string
  default     = "vanilla"
}

variable "minecraft_server_version" {
  description = "Minecraft version number. Defaults to 1.19.2"
  type        = string
  default     = "1.19.2"
}

variable "minecraft_jre_version" {
  description = "The JRE version to install for the minecraft server. From Minecraft 1.17 to 1.17.1 JRE 16 or newer is needed. For Minecraft 1.18 and beyond, use JRE 17. For everything 1.16 and below, use JRE 8"
  type        = string
  default     = "17"
}

variable "minecraft_jre_min_mem" {
  description = "Number of gigs to allocate as minimum memory for the server. Defaults to 2 for 2GB"
  type        = string
  default     = "2"
}

variable "minecraft_jre_max_mem" {
  description = "Number of gigs to allocate as maximum memory for the server. Defaults to 3 for 3GB"
  type        = string
  default     = "3"
}

variable "resource_pool_id" {
  description = "The resource pool ID to store the containers in. Defaults to lxc-general"
  type        = string
  default     = "lxc-general"
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