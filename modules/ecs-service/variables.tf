# ====================================================================
# ECS Service Module Variables
# ====================================================================

# ====================================================================
# Required Infrastructure Variables
# ====================================================================
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

# ====================================================================
# Service Configuration Map
# - Use for_each to create multiple services
# ====================================================================
variable "services" {
  description = "Map of ECS services to create"
  type = map(object({
    # Task Definition Configuration
    family                = string           # Task definition family name
    cpu                   = number           # CPU units (256, 512, 1024, 2048, 4096)
    memory                = number           # Memory in MB
    container_port        = number           # Port that container listens on
    host_port             = optional(number) # Host port (for bridge networking)

    # Container Configuration
    image                 = string                    # Container image URI
    essential             = optional(bool, true)      # Whether container is essential
    command               = optional(list(string))    # Override container command
    entrypoint           = optional(list(string))    # Override container entrypoint
    working_directory    = optional(string)          # Working directory

    # Environment Variables
    environment_variables = optional(map(string), {}) # Environment variables
    secrets              = optional(map(string), {})  # Secrets from SSM/Secrets Manager

    # Service Configuration
    desired_count        = optional(number, 1)        # Number of tasks to run
    enable_service       = optional(bool, true)       # Whether to create ECS service

    # Load Balancer Configuration
    enable_load_balancer = optional(bool, true)       # Whether to create ALB
    health_check_path    = optional(string, "/")      # Health check endpoint
    health_check_port    = optional(string, "traffic-port")
    health_check_protocol = optional(string, "HTTP")
    health_check_matcher = optional(string, "200")

    # Domain Configuration
    domain_name          = optional(string)           # Custom domain (subdomain.meiko.co.kr)
    certificate_arn      = optional(string)           # SSL certificate ARN

    # Deployment Configuration
    deployment_minimum_healthy_percent = optional(number, 50)
    deployment_maximum_percent        = optional(number, 200)
    enable_execute_command           = optional(bool, false)

    # Logging Configuration
    log_retention_days   = optional(number, 7)        # CloudWatch log retention

    # Auto Scaling Configuration
    enable_autoscaling   = optional(bool, false)      # Enable auto scaling
    min_capacity         = optional(number, 1)        # Min tasks for auto scaling
    max_capacity         = optional(number, 10)       # Max tasks for auto scaling
    target_cpu_utilization = optional(number, 70)     # CPU target for scaling
    target_memory_utilization = optional(number, 80)  # Memory target for scaling

    # Service Discovery Configuration
    enable_service_discovery = optional(bool, false)  # Enable service discovery
    service_discovery_namespace_id = optional(string) # Service discovery namespace ID

    # Security Configuration
    assign_public_ip     = optional(bool, false)      # Whether to assign public IP
    security_group_rules = optional(map(object({      # Additional security group rules
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string))
      source_security_group_id = optional(string)
    })), {})
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
}

# ====================================================================
# Global Configuration
# ====================================================================
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ====================================================================
# Route53 Configuration (Optional)
# ====================================================================
variable "route53_zone_id" {
  description = "Route53 hosted zone ID for creating DNS records"
  type        = string
  default     = ""
}

variable "default_certificate_arn" {
  description = "Default SSL certificate ARN for HTTPS listeners"
  type        = string
  default     = ""
}

# ====================================================================
# Advanced Configuration
# ====================================================================
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for services"
  type        = bool
  default     = false
}

variable "default_security_group_rules" {
  description = "Default security group rules for all services"
  type = map(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    source_security_group_id = optional(string)
  }))
  default = {}
}

variable "platform_version" {
  description = "Platform version for Fargate tasks"
  type        = string
  default     = "LATEST"
}