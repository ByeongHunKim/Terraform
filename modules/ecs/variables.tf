# ====================================================================
# ECS Module Variables
# ====================================================================

# ====================================================================
# Required Variables
# ====================================================================
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS cluster will be deployed"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# ====================================================================
# Capacity Provider Configuration
# ====================================================================
variable "capacity_providers" {
  description = "List of capacity providers for the ECS cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition = length(var.capacity_providers) > 0
    error_message = "At least one capacity provider must be specified."
  }
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  type = list(object({
    capacity_provider = string
    weight           = number
    base            = optional(number)
  }))
  default = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight           = 1
      base            = 0
    },
    {
      capacity_provider = "FARGATE"
      weight           = 1
      base            = 1
    }
  ]
}

# ====================================================================
# Monitoring and Logging Configuration
# ====================================================================
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = false  # Disabled by default to save costs
}

variable "log_retention_in_days" {
  description = "CloudWatch log group retention period in days"
  type        = number
  default     = 7  # Short retention for cost optimization

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_in_days)
    error_message = "Log retention period must be a valid CloudWatch Logs retention value."
  }
}

# ====================================================================
# Service Discovery Configuration
# ====================================================================
variable "create_service_discovery_namespace" {
  description = "Whether to create a service discovery namespace"
  type        = bool
  default     = false  # Disabled by default for cost optimization
}

variable "service_discovery_namespace" {
  description = "Name of the service discovery namespace"
  type        = string
  default     = ""
}

# ====================================================================
# IAM Configuration
# ====================================================================
variable "create_execution_role" {
  description = "Whether to create ECS task execution role"
  type        = bool
  default     = true  # Usually needed for most ECS tasks
}

# ====================================================================
# Tagging
# ====================================================================
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

# ====================================================================
# Optional Features (for future phases)
# ====================================================================
variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging containers"
  type        = bool
  default     = false  # Disabled by default
}

variable "cluster_configuration" {
  description = "Additional cluster configuration"
  type = object({
    execute_command_configuration = optional(object({
      logging = optional(string, "DEFAULT")
    }))
  })
  default = {}
}