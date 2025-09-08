# ====================================================================
# ACM Module Variables
# ====================================================================
variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "List of additional domain names to include in the certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Validation method for the certificate (DNS or EMAIL)"
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "Validation method must be either DNS or EMAIL."
  }
}

variable "create_route53_records" {
  description = "Whether to create Route53 validation records automatically"
  type        = bool
  default     = true
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation (required if create_route53_records is true)"
  type        = string
  default     = ""
}

variable "wait_for_validation" {
  description = "Whether to wait for certificate validation to complete"
  type        = bool
  default     = true
}

variable "validation_timeout" {
  description = "Timeout for certificate validation"
  type        = string
  default     = "5m"
}

variable "certificate_transparency_logging_preference" {
  description = "Certificate transparency logging preference (ENABLED or DISABLED)"
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.certificate_transparency_logging_preference)
    error_message = "Certificate transparency logging preference must be either ENABLED or DISABLED."
  }
}

variable "key_algorithm" {
  description = "Key algorithm for the certificate"
  type        = string
  default     = "RSA_2048"

  validation {
    condition = contains([
      "RSA_1024", "RSA_2048", "RSA_3072", "RSA_4096",
      "EC_prime256v1", "EC_secp384r1", "EC_secp521r1"
    ], var.key_algorithm)
    error_message = "Key algorithm must be a valid ACM-supported algorithm."
  }
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ====================================================================
# Wildcard Certificate Support
# ====================================================================
variable "create_wildcard_certificate" {
  description = "Whether to create a wildcard certificate"
  type        = bool
  default     = false
}

variable "wildcard_domain" {
  description = "Wildcard domain name (e.g., *.example.com)"
  type        = string
  default     = ""
}