# ====================================================================
# ECS Module Outputs
# ====================================================================

# ====================================================================
# ECS Cluster Outputs
# ====================================================================
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_capacity_providers" {
  description = "Capacity providers associated with the cluster"
  value       = aws_ecs_cluster_capacity_providers.main.capacity_providers
}

# ====================================================================
# CloudWatch Logging Outputs
# ====================================================================
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.arn
}

# ====================================================================
# IAM Role Outputs
# ====================================================================
output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = var.create_execution_role ? aws_iam_role.ecs_execution_role[0].arn : null
}

output "execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = var.create_execution_role ? aws_iam_role.ecs_execution_role[0].name : null
}

# ====================================================================
# Service Discovery Outputs
# ====================================================================
output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = var.create_service_discovery_namespace ? aws_service_discovery_private_dns_namespace.ecs[0].id : null
}

output "service_discovery_namespace_arn" {
  description = "ARN of the service discovery namespace"
  value       = var.create_service_discovery_namespace ? aws_service_discovery_private_dns_namespace.ecs[0].arn : null
}

output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = var.create_service_discovery_namespace ? aws_service_discovery_private_dns_namespace.ecs[0].name : null
}

# ====================================================================
# Configuration Summary
# ====================================================================
output "cluster_configuration" {
  description = "Summary of cluster configuration"
  value = {
    name                    = aws_ecs_cluster.main.name
    capacity_providers      = aws_ecs_cluster_capacity_providers.main.capacity_providers
    container_insights      = var.enable_container_insights
    log_retention_days     = var.log_retention_in_days
    execution_role_created = var.create_execution_role
    service_discovery      = var.create_service_discovery_namespace
  }
}

# ====================================================================
# For Task Definition Creation (Future Phases)
# ====================================================================
output "task_definition_family_prefix" {
  description = "Recommended prefix for task definition families"
  value       = "${var.cluster_name}-task"
}

output "log_group_name_for_tasks" {
  description = "CloudWatch log group name to use in task definitions"
  value       = aws_cloudwatch_log_group.ecs.name
}