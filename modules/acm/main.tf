# ====================================================================
# Data Sources
# ====================================================================
data "aws_route53_zone" "selected" {
  count   = var.create_route53_records && var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
}

# ====================================================================
# ACM Certificate - Unified Certificate (Primary + Wildcard)
# ====================================================================
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = var.validation_method

  # 🌟 와일드카드 도메인을 SAN으로 포함 (선택적)
  subject_alternative_names = var.create_wildcard_certificate ? concat(
    var.subject_alternative_names,
    ["*.${var.domain_name}"]
  ) : var.subject_alternative_names

  key_algorithm = var.key_algorithm

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-certificate"
    Domain      = var.domain_name
    Type        = var.create_wildcard_certificate ? "Unified" : "Standard"
    Purpose     = var.create_wildcard_certificate ? "SSL/TLS Certificate with Wildcard" : "SSL/TLS Certificate"
    Coverage    = var.create_wildcard_certificate ? "Primary and Wildcard domains" : "Primary domain only"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ====================================================================
# Route53 Validation Records - Main Certificate (모든 도메인 커버)
# ====================================================================
resource "aws_route53_record" "main_validation" {
  for_each = var.validation_method == "DNS" && var.create_route53_records ? {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id

  depends_on = [aws_acm_certificate.main]
}

# ====================================================================
# Certificate Validation - Main Certificate (모든 도메인 검증)
# ====================================================================
resource "aws_acm_certificate_validation" "main" {
  count = var.wait_for_validation && var.validation_method == "DNS" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = var.create_route53_records ? [for record in aws_route53_record.main_validation : record.fqdn] : []

  timeouts {
    create = var.validation_timeout
  }

  depends_on = [aws_route53_record.main_validation]
}