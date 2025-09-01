# ====================================================================
# Terraform Cloud OIDC Module Outputs
# ====================================================================
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.terraform_cloud.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = aws_iam_openid_connect_provider.terraform_cloud.url
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.terraform_cloud.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.terraform_cloud.name
}

output "trust_policy" {
  description = "Trust policy JSON document"
  value       = data.aws_iam_policy_document.terraform_cloud_trust.json
}