# ====================================================================
# Environment Configuration - Development Settings
# - Modify these values for different environments
# - All environment-specific settings in one place
# ====================================================================
locals {
  # Environment Settings - CHANGE THESE VALUES FOR DIFFERENT ENVIRONMENTS
  environment = "dev"                    # Environment: dev, staging, prod
  project     = "terraform-study"        # Project name
  owner       = "meiko"                  # Owner/Team name
  region      = "ap-northeast-2"         # AWS region

  # Terraform Cloud Settings
  tfc_organization = "Meiko_Org"
  tfc_workspace    = "Meiko"

  # GitHub Settings
  github_organization = "ByeongHunKim"  # GitHub username or organization
  github_repository   = "Terraform"        # GitHub repository name

  # Cost Optimization Settings for Development
  enable_nat_gateway = false             # Disable NAT Gateway to save costs in dev

  # Network Configuration
  vpc_cidr_block = "10.0.0.0/16"         # VPC CIDR block
  public_cidrs = [                       # Public subnet CIDR blocks
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  private_cidrs = [                      # Private subnet CIDR blocks
    "10.0.10.0/24",
    "10.0.20.0/24"
  ]

  database_cidrs = [                     # Database subnet CIDR blocks
    "10.0.100.0/27",
    "10.0.200.0/27"
  ]

  # SSL/TLS Certificate Configuration
  primary_domain = "meiko.co.kr"
  create_wildcard = true
  route53_zone_id = var.ROUTE53_PUB_ZONE_ID

  # Common Tags - Applied to all resources
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Owner       = local.owner
    Region      = local.region
    CostCenter  = "${local.project}-${local.environment}"
  }
}

# ====================================================================
# Terraform Cloud OIDC Module
# - Creates OIDC provider and role for Terraform Cloud Dynamic Provider
# ====================================================================
module "terraform_cloud_oidc" {
  source = "../modules/terraform-cloud-oidc"

  # Terraform Cloud Settings
  terraform_cloud_organization = local.tfc_organization
  workspace_name               = local.tfc_workspace

  # IAM Role Configuration
  role_name = "${local.project}-${local.environment}-tfc-role"

  # Naming and Tagging
  name_prefix = "${local.project}-${local.environment}"
  tags        = local.common_tags
}

# ====================================================================
# GitHub Actions OIDC Module
# - Creates OIDC provider and role for GitHub Actions
# - Same structure as terraform_cloud_oidc with AdministratorAccess
# ====================================================================
module "github_actions_oidc" {
  source = "../modules/github-actions-oidc"

  # GitHub Settings
  github_organization = local.github_organization
  repository_name     = local.github_repository

  # IAM Role Configuration
  role_name = "${local.project}-${local.environment}-github-actions-role"

  # IAM Policies - Administrator Access (same as Terraform Cloud)
  policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  # Naming and Tagging
  name_prefix = "${local.project}-${local.environment}"
  tags        = local.common_tags
}

# ====================================================================
# VPC Module - Network Infrastructure
# - Creates VPC with public and private subnets
# - Internet Gateway for public subnet connectivity
# - NAT Gateway controlled by local settings
# ====================================================================
module "vpc" {
  source = "../modules/vpc"

  # Network Configuration
  vpc_cidr           = local.vpc_cidr_block
  public_subnets     = local.public_cidrs
  private_subnets    = local.private_cidrs
  database_subnets   = local.database_cidrs
  enable_nat_gateway = local.enable_nat_gateway

  create_database_subnet_group = true
  database_subnet_group_name   = "${local.project}-${local.environment}-db-subnet-group"

  # Naming and Tagging
  name_prefix = "${local.project}-${local.environment}"
  tags        = local.common_tags
}

# ====================================================================
# ACM Module - SSL/TLS Certificate Management for meiko.co.kr
# - Creates SSL/TLS certificates for meiko.co.kr domain
# - Automatic DNS validation with existing Route53 hosted zone
# - Supports both single domain and wildcard certificates
# ====================================================================
module "acm" {
  source = "../modules/acm"

  # Domain Configuration
  domain_name = local.primary_domain

  create_wildcard_certificate = local.create_wildcard
  wildcard_domain            = "*.${local.primary_domain}"

  # DNS Validation Configuration
  validation_method        = "DNS"
  create_route53_records   = true
  route53_zone_id         = local.route53_zone_id
  wait_for_validation     = true

  # Certificate Security Configuration
  key_algorithm = "RSA_2048"                                # RSA 2048-bit key
  certificate_transparency_logging_preference = "ENABLED"   # CT logging enable

  name_prefix = "${local.project}-${local.environment}"
  tags = merge(local.common_tags, {
    Purpose = "SSL/TLS Certificate"
    Domain  = local.primary_domain
    Type    = "Production-Ready"
  })
}