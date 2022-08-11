output "ip_address" {
  description = "IP address of the VM"
  value       = proxmox_vm_qemu.main.default_ipv4_address
}

output "k8s_certificate_key" {
  description = "Certificate key of the primary controller"
  sensitive   = true
  value       = random_password.certificate_key.result
}