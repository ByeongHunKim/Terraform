# ====================================================================
# Enhanced Variables with Comprehensive Validation
# ====================================================================

# ====================================================================
# Basic Environment Configuration
# ====================================================================
variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod."
  }
}

variable "project" {
  description = "Project name - used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "owner" {
  description = "Resource owner name"
  type        = string

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner name cannot be empty."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition = contains([
      "us-east-1", "us-west-2", "ap-northeast-1",
      "ap-northeast-2", "eu-west-1", "ap-southeast-1"
    ], var.aws_region)
    error_message = "AWS region must be a supported region."
  }
}

# ====================================================================
# External Service Integration Variables
# ====================================================================
variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string

  validation {
    condition     = length(var.tfc_organization) > 0
    error_message = "Terraform Cloud organization name cannot be empty."
  }
}

variable "tfc_workspace" {
  description = "Terraform Cloud workspace name"
  type        = string

  validation {
    condition     = length(var.tfc_workspace) > 0
    error_message = "Terraform Cloud workspace name cannot be empty."
  }
}

variable "github_organization" {
  description = "GitHub organization or username"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.github_organization))
    error_message = "GitHub organization must contain only letters, numbers, and hyphens."
  }
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_.]+$", var.github_repository))
    error_message = "GitHub repository name contains invalid characters."
  }
}

# ====================================================================
# Network Configuration Variables
# ====================================================================
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid CIDR notation."
  }

  validation {
    condition     = split("/", var.vpc_cidr_block)[1] <= "24"
    error_message = "VPC CIDR block must be /24 or larger (smaller number)."
  }
}

variable "public_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.public_cidrs) >= 2
    error_message = "At least 2 public subnets required for high availability."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid CIDR notation."
  }
}

variable "private_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.private_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet CIDRs must be valid CIDR notation."
  }
}

variable "database_cidrs" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.database_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All database subnet CIDRs must be valid CIDR notation."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

# ====================================================================
# Domain and SSL Configuration
# ====================================================================
variable "primary_domain" {
  description = "Primary domain name for SSL certificate"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.primary_domain))
    error_message = "Primary domain must be a valid domain name."
  }
}

variable "create_wildcard" {
  description = "Create wildcard SSL certificate"
  type        = bool
  default     = true
}

# ====================================================================
# ECS Service Configuration
# ====================================================================
variable "nginx_service" {
  description = "Nginx service configuration"
  type = object({
    # Container Configuration
    image          = string
    cpu            = number
    memory         = number
    container_port = number

    # Service Configuration
    desired_count        = number
    enable_service       = bool
    enable_load_balancer = bool

    # Domain Configuration
    domain_name = string

    # Auto Scaling Configuration
    enable_autoscaling       = bool
    min_capacity            = number
    max_capacity            = number
    target_cpu_utilization  = number

    # Health Check Configuration
    health_check_path    = string
    health_check_matcher = string

    # Logging Configuration
    log_retention_days = number

    # Environment Variables
    environment_variables = map(string)
  })

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.nginx_service.cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }

  validation {
    condition     = var.nginx_service.memory >= 512 && var.nginx_service.memory <= 30720
    error_message = "Memory must be between 512 MB and 30720 MB."
  }

  validation {
    condition     = var.nginx_service.container_port > 0 && var.nginx_service.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }

  validation {
    condition     = var.nginx_service.desired_count >= 0
    error_message = "Desired count must be 0 or greater."
  }

  validation {
    condition     = var.nginx_service.min_capacity <= var.nginx_service.max_capacity
    error_message = "Min capacity must be less than or equal to max capacity."
  }

  validation {
    condition     = var.nginx_service.target_cpu_utilization > 0 && var.nginx_service.target_cpu_utilization <= 100
    error_message = "Target CPU utilization must be between 1 and 100."
  }

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.nginx_service.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention value."
  }
}

# ====================================================================
# ECS Cluster Configuration
# ====================================================================
variable "ecs_cluster" {
  description = "ECS cluster configuration"
  type = object({
    capacity_providers                     = list(string)
    enable_container_insights             = bool
    log_retention_in_days                 = number
    create_service_discovery_namespace    = bool
    create_execution_role                 = bool
    capacity_provider_strategy = list(object({
      capacity_provider = string
      weight           = number
      base            = number
    }))
  })

  validation {
    condition = alltrue([
      for provider in var.ecs_cluster.capacity_providers :
      contains(["FARGATE", "FARGATE_SPOT", "EC2"], provider)
    ])
    error_message = "Capacity providers must be one of: FARGATE, FARGATE_SPOT, EC2."
  }

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.ecs_cluster.log_retention_in_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention value."
  }
}

# ====================================================================
# ACM Certificate Configuration
# ====================================================================
variable "acm_config" {
  description = "ACM certificate configuration"
  type = object({
    validation_method                           = string
    create_route53_records                     = bool
    wait_for_validation                        = bool
    key_algorithm                              = string
    certificate_transparency_logging_preference = string
  })

  validation {
    condition     = contains(["DNS", "EMAIL"], var.acm_config.validation_method)
    error_message = "Validation method must be DNS or EMAIL."
  }

  validation {
    condition = contains([
      "RSA_1024", "RSA_2048", "RSA_3072", "RSA_4096",
      "EC_prime256v1", "EC_secp384r1", "EC_secp521r1"
    ], var.acm_config.key_algorithm)
    error_message = "Key algorithm must be a valid ACM-supported algorithm."
  }

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.acm_config.certificate_transparency_logging_preference)
    error_message = "Certificate transparency logging must be ENABLED or DISABLED."
  }
}

# ====================================================================
# Sensitive Variables
# ====================================================================
variable "ROUTE53_PUB_ZONE_ID" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.ROUTE53_PUB_ZONE_ID))
    error_message = "Route53 zone ID must start with 'Z' followed by alphanumeric characters."
  }
}