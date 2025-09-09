# ====================================================================
# ECS Cluster Module - Container Orchestration Platform
# - Creates ECS cluster with Fargate support
# - CloudWatch logging configuration
# - Cost-optimized setup (cluster only, no running tasks)
# ====================================================================

# ====================================================================
# ECS Cluster - Main Container Orchestration Platform
# - Fargate and EC2 capacity providers support
# - Container insights for monitoring
# ====================================================================
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  # Container Insights for monitoring (optional, can be disabled to save costs)
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name        = var.cluster_name
    Type        = "ECS Cluster"
    Purpose     = "Container Orchestration"
    Environment = var.environment
  })
}

# ====================================================================
# ECS Cluster Capacity Providers - Compute Capacity Management
# - Fargate and Fargate Spot for cost optimization
# - EC2 capacity provider (optional, for mixed workloads)
# ====================================================================
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = var.capacity_providers

  # Default capacity provider strategy
  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight           = default_capacity_provider_strategy.value.weight
      base            = lookup(default_capacity_provider_strategy.value, "base", null)
    }
  }
}

# ====================================================================
# CloudWatch Log Group - ECS Container Logging
# - Centralized logging for all ECS tasks
# - Configurable retention period
# ====================================================================
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name    = "/ecs/${var.cluster_name}"
    Type    = "CloudWatch Log Group"
    Purpose = "ECS Container Logs"
  })
}

# ====================================================================
# ECS Cluster Service Connect Configuration (Optional)
# - Service discovery and load balancing for microservices
# - Only create if namespace is provided
# ====================================================================
resource "aws_service_discovery_private_dns_namespace" "ecs" {
  count = var.create_service_discovery_namespace ? 1 : 0

  name = var.service_discovery_namespace
  vpc  = var.vpc_id

  tags = merge(var.tags, {
    Name    = var.service_discovery_namespace
    Type    = "Service Discovery Namespace"
    Purpose = "ECS Service Connect"
  })
}

# ====================================================================
# ECS Execute Role - Required for ECS Exec (debugging)
# - Allows exec into running containers
# - Optional, only created if enabled
# ====================================================================
resource "aws_iam_role" "ecs_execution_role" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.cluster_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-execution-role"
    Type    = "IAM Role"
    Purpose = "ECS Task Execution"
  })
}

# ====================================================================
# ECS Execution Role Policy Attachment
# ====================================================================
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  count = var.create_execution_role ? 1 : 0

  role       = aws_iam_role.ecs_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ====================================================================
# Additional CloudWatch Logs Permissions for Execution Role
# ====================================================================
resource "aws_iam_role_policy" "ecs_execution_role_logs" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.cluster_name}-execution-logs"
  role = aws_iam_role.ecs_execution_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      }
    ]
  })
}