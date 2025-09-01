# ====================================================================
# Development Environment Outputs
# ====================================================================

# Terraform Cloud OIDC Outputs
output "terraform_cloud_oidc_provider_arn" {
  description = "ARN of the Terraform Cloud OIDC provider"
  value       = module.terraform_cloud_oidc.oidc_provider_arn
}

output "terraform_cloud_role_arn" {
  description = "ARN of the Terraform Cloud IAM role"
  value       = module.terraform_cloud_oidc.role_arn
}

output "terraform_cloud_role_name" {
  description = "Name of the Terraform Cloud IAM role"
  value       = module.terraform_cloud_oidc.role_name
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}