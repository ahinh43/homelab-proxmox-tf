output "ip_address" {
  description = "IP address of the VM"
  value       = proxmox_vm_qemu.main.default_ipv4_address
}