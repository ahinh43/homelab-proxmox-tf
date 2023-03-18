resource "cloudflare_record" "main" {
  zone_id = var.zone_id
  name    = var.record_name
  value   = var.record_target
  type    = var.record_type
  ttl     = var.record_ttl
}
