# ====================================================================
# ACM Module Outputs - Unified Certificate
# ====================================================================

# ====================================================================
# Main Certificate Outputs (Primary + Wildcard)
# ====================================================================
output "certificate_arn" {
  description = "ARN of the unified certificate (covers both primary and wildcard domains)"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain_name" {
  description = "Primary domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.main.status
}

output "certificate_validation_emails" {
  description = "Validation emails for the certificate (if using EMAIL validation)"
  value       = aws_acm_certificate.main.validation_emails
}

output "certificate_domain_validation_options" {
  description = "Domain validation options for the certificate"
  value       = aws_acm_certificate.main.domain_validation_options
  sensitive   = true
}

# ====================================================================
# Wildcard Certificate Outputs (same as main certificate)
# ====================================================================
output "wildcard_certificate_arn" {
  description = "ARN of the wildcard certificate (same as main certificate)"
  value       = var.create_wildcard_certificate ? aws_acm_certificate.main.arn : null
}

output "wildcard_certificate_domain_name" {
  description = "Wildcard domain name covered by the certificate"
  value       = var.create_wildcard_certificate ? "*.${var.domain_name}" : null
}

output "wildcard_certificate_status" {
  description = "Status of the wildcard certificate (same as main certificate)"
  value       = var.create_wildcard_certificate ? aws_acm_certificate.main.status : null
}

# ====================================================================
# Validation Outputs
# ====================================================================
output "validation_records" {
  description = "Route53 validation records created"
  value = var.create_route53_records ? {
    main     = aws_route53_record.main_validation
    wildcard = {} # Empty since wildcard is included in main
  } : {}
}

output "validated_certificate_arn" {
  description = "ARN of the validated certificate"
  value       = var.wait_for_validation && var.validation_method == "DNS" ? aws_acm_certificate_validation.main[0].certificate_arn : aws_acm_certificate.main.arn
}

output "validated_wildcard_certificate_arn" {
  description = "ARN of the validated wildcard certificate (same as main)"
  value       = var.create_wildcard_certificate ? (var.wait_for_validation && var.validation_method == "DNS" ? aws_acm_certificate_validation.main[0].certificate_arn : aws_acm_certificate.main.arn) : null
}

# ====================================================================
# All Certificates Summary
# ====================================================================
output "all_certificate_arns" {
  description = "List of all certificate ARNs created (single unified certificate)"
  value       = [aws_acm_certificate.main.arn]
}

output "all_domain_names" {
  description = "List of all domain names covered by the certificate"
  value = compact(concat(
    [aws_acm_certificate.main.domain_name],
    length(aws_acm_certificate.main.subject_alternative_names) > 0 ? tolist(aws_acm_certificate.main.subject_alternative_names) : []
  ))
}

# ====================================================================
# Metadata Outputs
# ====================================================================
output "certificate_key_algorithm" {
  description = "Key algorithm used for the certificate"
  value       = var.key_algorithm
}

output "validation_method" {
  description = "Validation method used for the certificate"
  value       = var.validation_method
}

output "route53_zone_id" {
  description = "Route53 zone ID used for validation"
  value       = var.route53_zone_id
}

output "is_unified_certificate" {
  description = "Whether this is a unified certificate covering both primary and wildcard domains"
  value       = var.create_wildcard_certificate
}

output "domains_covered" {
  description = "Summary of domains covered by this certificate"
  value = {
    primary_domain   = aws_acm_certificate.main.domain_name
    includes_wildcard = var.create_wildcard_certificate
    wildcard_domain  = var.create_wildcard_certificate ? "*.${var.domain_name}" : null
    all_domains      = tolist(aws_acm_certificate.main.subject_alternative_names)
  }
}