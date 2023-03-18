variable "record_name" {
  description = "The record name to create. Required"
  type        = string
}

variable "record_type" {
  description = "The record type. Such as CNAME, A, AAAA, etc."
  type        = string
  default = "A"
}

variable "record_target" {
  description = "Target IP address of the record. Required."
  type        = string
}

variable "record_ttl" {

  description = "TTL value of the domain. Defaults to 3600."
  type        = number
  default     = 3600
}

variable "zone_id" {
  description = "The zone ID to configure the record in. Required."
  type        = string
}