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
  enable_nat_gateway = local.enable_nat_gateway

  # Naming and Tagging
  name_prefix = "${local.project}-${local.environment}"
  tags        = local.common_tags
}