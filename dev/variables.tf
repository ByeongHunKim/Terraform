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
# ECS Services Configuration
# ====================================================================
variable "services" {
  description = "Map of ECS services to create"
  type = map(object({
    # Task Definition Configuration
    family         = string           # Task definition family name
    cpu            = number
    memory         = number
    container_port = number

    # Container Configuration
    image          = string

    # Optional container configuration
    command               = optional(list(string))
    entrypoint           = optional(list(string))
    working_directory    = optional(string)
    essential            = optional(bool, true)

    # Service Configuration
    desired_count        = number
    enable_service       = bool
    enable_load_balancer = bool

    # Domain Configuration
    domain_name = optional(string)

    # Auto Scaling Configuration
    enable_autoscaling       = bool
    min_capacity            = optional(number, 1)
    max_capacity            = optional(number, 10)
    target_cpu_utilization  = optional(number, 70)
    target_memory_utilization = optional(number, 80)

    # Health Check Configuration
    health_check_path    = string
    health_check_matcher = string
    health_check_port    = optional(string, "traffic-port")
    health_check_protocol = optional(string, "HTTP")

    # Logging Configuration
    log_retention_days = number

    # Environment Variables and Secrets
    environment_variables = map(string)
    secrets              = optional(map(string), {})

    # Deployment Configuration
    deployment_minimum_healthy_percent = optional(number, 50)
    deployment_maximum_percent        = optional(number, 200)
    enable_execute_command           = optional(bool, false)

    # Network Configuration
    assign_public_ip = optional(bool, false)

    # Security Configuration
    security_group_rules = optional(map(object({
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string))
      source_security_group_id = optional(string)
    })), {})

    # Service Discovery
    enable_service_discovery = optional(bool, false)
    service_discovery_namespace_id = optional(string)
  }))

  validation {
    condition = alltrue([
      for service in var.services : contains([256, 512, 1024, 2048, 4096], service.cpu)
    ])
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }

  validation {
    condition = alltrue([
      for service in var.services : service.memory >= 512 && service.memory <= 30720
      ])
    error_message = "Memory must be between 512 MB and 30720 MB."
  }

  validation {
    condition = alltrue([
      for service in var.services : service.container_port > 0 && service.container_port <= 65535
      ])
    error_message = "Container port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for service in var.services : service.desired_count >= 0
      ])
    error_message = "Desired count must be 0 or greater."
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
  # sensitive   = true

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.ROUTE53_PUB_ZONE_ID))
    error_message = "Route53 zone ID must start with 'Z' followed by alphanumeric characters."
  }
}

# ====================================================================
# Image Configuration
# ====================================================================
variable "use_ecr_images" {
  description = "Whether to use ECR images instead of public Docker Hub images"
  type        = bool
  default     = false
}

# ====================================================================
# VPC Flow Logs Configuration
# ====================================================================
variable "vpc_flow_logs_config" {
  description = "VPC Flow Logs configuration"
  type = object({
    # CloudWatch Log Group
    log_group_name        = string
    log_retention_in_days = number

    # IAM Role
    iam_role_name = string

    # Flow Log Settings
    traffic_type             = string
    max_aggregation_interval = number
    log_format              = optional(string)
  })

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.vpc_flow_logs_config.traffic_type)
    error_message = "Traffic type must be one of: ACCEPT, REJECT, ALL."
  }

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.vpc_flow_logs_config.log_retention_in_days)
    error_message = "Log retention period must be a valid CloudWatch Logs retention value."
  }

  validation {
    condition     = contains([60, 600], var.vpc_flow_logs_config.max_aggregation_interval)
    error_message = "Max aggregation interval must be either 60 or 600 seconds."
  }
}