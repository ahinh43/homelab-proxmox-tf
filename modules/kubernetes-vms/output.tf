output "ip_address" {
  description = "IP address of the VM"
  value       = proxmox_virtual_environment_vm.main.ipv4_addresses
}

output "custom_ip_address" {
  description = "Custom IP address set for the VM (not the default DHCP one)"
  value       = var.vm_ip_address
}