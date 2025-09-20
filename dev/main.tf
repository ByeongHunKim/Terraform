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

  # Global Configuration
  environment             = var.environment
  name_prefix             = local.name_prefix
  route53_zone_id         = var.ROUTE53_PUB_ZONE_ID
  default_certificate_arn = module.acm.certificate_arn

  services = {
    "nginx-web" = {
      # Task Definition Configuration
      family         = "${local.name_prefix}-nginx"
      cpu            = var.nginx_service.cpu
      memory         = var.nginx_service.memory
      container_port = var.nginx_service.container_port

      # Container Configuration
      image = var.nginx_service.image
      environment_variables = var.nginx_service.environment_variables

      # Service Configuration
      desired_count        = var.nginx_service.desired_count
      enable_service       = var.nginx_service.enable_service
      enable_load_balancer = var.nginx_service.enable_load_balancer

      # Health Check Configuration
      health_check_path    = var.nginx_service.health_check_path
      health_check_matcher = var.nginx_service.health_check_matcher

      # Domain Configuration
      domain_name     = var.nginx_service.domain_name
      certificate_arn = module.acm.certificate_arn

      # Auto Scaling Configuration
      enable_autoscaling       = var.nginx_service.enable_autoscaling
      min_capacity            = var.nginx_service.min_capacity
      max_capacity            = var.nginx_service.max_capacity
      target_cpu_utilization  = var.nginx_service.target_cpu_utilization

      # Logging Configuration
      log_retention_days = var.nginx_service.log_retention_days
    }
  }

  # Common Tags
  tags = merge(local.common_tags, {
    Module  = "ecs-services"
    Purpose = "Container Services"
    Phase   = "2 - Task Definitions and Services"
  })
}