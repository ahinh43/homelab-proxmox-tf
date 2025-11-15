resource "cloudflare_dns_record" "main" {
  zone_id = var.zone_id
  name    = var.record_name
  ttl     = var.record_ttl
  type    = var.record_type
  comment = "Server"
  content = var.record_target
  proxied = false
}