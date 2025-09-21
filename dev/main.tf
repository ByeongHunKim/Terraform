# ====================================================================
# Local Values
# ====================================================================
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = var.owner
    Region      = var.aws_region
    CostCenter  = "${var.project}-${var.environment}"
  }

  name_prefix = "${var.project}-${var.environment}"

  cluster_name = "${local.name_prefix}-cluster"
}

# ====================================================================
# Terraform Cloud OIDC Module
# ====================================================================
module "terraform_cloud_oidc" {
  source = "../modules/terraform-cloud-oidc"

  terraform_cloud_organization = var.tfc_organization
  workspace_name               = var.tfc_workspace

  role_name = "${local.name_prefix}-tfc-role"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# ====================================================================
# GitHub Actions OIDC Module
# ====================================================================
module "github_actions_oidc" {
  source = "../modules/github-actions-oidc"

  github_organization = var.github_organization
  repository_name     = var.github_repository

  role_name = "${local.name_prefix}-github-actions-role"

  policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# ====================================================================
# VPC Module
# ====================================================================
module "vpc" {
  source = "../modules/vpc"

  vpc_cidr           = var.vpc_cidr_block
  public_subnets     = var.public_cidrs
  private_subnets    = var.private_cidrs
  database_subnets   = var.database_cidrs
  enable_nat_gateway = var.enable_nat_gateway

  # Database Subnet Group
  create_database_subnet_group = true
  database_subnet_group_name   = "${local.name_prefix}-db-subnet-group"

  # Naming and Tagging
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# ====================================================================
# ACM Module
# ====================================================================
module "acm" {
  source = "../modules/acm"

  domain_name = var.primary_domain

  create_wildcard_certificate = var.create_wildcard
  wildcard_domain            = "*.${var.primary_domain}"

  validation_method        = var.acm_config.validation_method
  create_route53_records   = var.acm_config.create_route53_records
  route53_zone_id         = var.ROUTE53_PUB_ZONE_ID
  wait_for_validation     = var.acm_config.wait_for_validation

  key_algorithm = var.acm_config.key_algorithm
  certificate_transparency_logging_preference = var.acm_config.certificate_transparency_logging_preference

  name_prefix = local.name_prefix
  tags = merge(local.common_tags, {
    Purpose = "SSL/TLS Certificate"
    Domain  = var.primary_domain
    Type    = "Production-Ready"
  })
}

# ====================================================================
# ECS Module
# ====================================================================
module "ecs" {
  source = "../modules/ecs"

  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment

  capacity_providers = var.ecs_cluster.capacity_providers
  default_capacity_provider_strategy = var.ecs_cluster.capacity_provider_strategy

  enable_container_insights           = var.ecs_cluster.enable_container_insights
  log_retention_in_days              = var.ecs_cluster.log_retention_in_days
  create_service_discovery_namespace = var.ecs_cluster.create_service_discovery_namespace
  create_execution_role              = var.ecs_cluster.create_execution_role

  tags = merge(local.common_tags, {
    Purpose = "Container Orchestration"
    Phase   = "1 - Cluster Only"
    NextStep = "Task Definitions and Services"
  })
}

# ====================================================================
# ECR Module
# ====================================================================
module "ecr" {
  source = "../modules/ecr"

  # ECR repositories for each service
  repositories = {
    for service_key, service in var.services : service_key => {
      # Image Configuration
      image_tag_mutability = var.environment == "prod" ? "IMMUTABLE" : "MUTABLE"
      scan_on_push        = true

      # Encryption
      encryption_type = "AES256"
      kms_key_id     = null

      # Lifecycle Policy
      lifecycle_policy_enabled = true
      keep_last_images        = var.environment == "prod" ? 50 : 10
      untagged_expire_days    = var.environment == "prod" ? 14 : 3

      # Access Control
      allowed_principals = [
        module.ecs.execution_role_arn,
        module.github_actions_oidc.role_arn
      ]

      # Development Configuration
      force_delete = var.environment == "dev"
    }
  }

  environment = var.environment
  name_prefix = local.name_prefix

  tags = merge(local.common_tags, {
    Module  = "ecr"
    Purpose = "Container Registry"
    Phase   = "1 - Image Storage"
  })
}

# ====================================================================
# ECS Service Module
# ====================================================================
module "ecs_services" {
  source = "../modules/ecs-service"

  # Infrastructure Configuration
  cluster_name         = module.ecs.cluster_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.public_subnet_ids  # temp: private_subnet_ids 사용시 NAT Gateway 필요
  execution_role_arn  = module.ecs.execution_role_arn

  environment             = var.environment
  name_prefix             = local.name_prefix
  route53_zone_id         = var.ROUTE53_PUB_ZONE_ID
  default_certificate_arn = module.acm.certificate_arn

  services = var.services

  # Common Tags
  tags = merge(local.common_tags, {
    Module  = "ecs-services"
    Purpose = "Container Services"
    Phase   = "2 - Task Definitions and Services"
  })
}