# ====================================================================
# Global Variables - Override from CLI or .tfvars files
# - These can override local values if needed
# ====================================================================

variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition = contains([
      "us-east-1", "us-west-2", "ap-northeast-1",
      "ap-northeast-2", "eu-west-1"
    ], var.aws_region)
    error_message = "AWS region must be a supported region."
  }
}

# ====================================================================
# Optional Override Variables
# - Use these to override local values via CLI or .tfvars
# ====================================================================

variable "environment_override" {
  description = "Override environment name (optional)"
  type        = string
  default     = null
}

variable "project_override" {
  description = "Override project name (optional)"
  type        = string
  default     = null
}

variable "enable_nat_gateway_override" {
  description = "Override NAT Gateway setting (optional)"
  type        = bool
  default     = null
}

# ====================================================================
# Terraform Cloud Override Variables (optional)
# ====================================================================

variable "tfc_organization_override" {
  description = "Override Terraform Cloud organization (optional)"
  type        = string
  default     = null
}

variable "tfc_workspace_override" {
  description = "Override Terraform Cloud workspace name (optional)"
  type        = string
  default     = null
}

variable "ROUTE53_PUB_ZONE_ID" {
  description = "Route53 hosted zone ID for DNS validation (required if create_route53_records is true)"
  type      = string
  nullable  = false
  sensitive = true
}