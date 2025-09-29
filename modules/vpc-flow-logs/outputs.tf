# ====================================================================
# Flow Log Outputs
# ====================================================================
output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.main.id
}

output "flow_log_arn" {
  description = "ARN of the VPC Flow Log"
  value       = aws_flow_log.main.arn
}

# ====================================================================
# CloudWatch Log Group Outputs
# ====================================================================
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.flow_logs.arn
}

output "log_retention_in_days" {
  description = "Log retention period in days"
  value       = aws_cloudwatch_log_group.flow_logs.retention_in_days
}

# ====================================================================
# IAM Role Outputs
# ====================================================================
output "iam_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.flow_logs.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.flow_logs.name
}

# ====================================================================
# Configuration Summary
# ====================================================================
output "flow_log_configuration" {
  description = "Summary of Flow Log configuration"
  value = {
    vpc_id                   = var.vpc_id
    traffic_type            = var.traffic_type
    log_destination         = aws_cloudwatch_log_group.flow_logs.arn
    log_retention_days      = aws_cloudwatch_log_group.flow_logs.retention_in_days
    max_aggregation_interval = var.max_aggregation_interval
  }
}