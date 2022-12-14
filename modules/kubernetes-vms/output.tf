output "ip_address" {
  description = "IP address of the VM"
  value       = proxmox_vm_qemu.main.default_ipv4_address
}

output "custom_ip_address" {
  description = "Custom IP address set for the VM (not the default DHCP one)"
  value       = var.vm_ip_address
}