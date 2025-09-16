# ====================================================================
# ECS Service Module Outputs
# ====================================================================

# ====================================================================
# Task Definition Outputs
# ====================================================================
output "task_definition_arns" {
  description = "ARNs of the ECS task definitions"
  value = {
    for key, task_def in aws_ecs_task_definition.main : key => task_def.arn
  }
}

output "task_definition_families" {
  description = "Families of the ECS task definitions"
  value = {
    for key, task_def in aws_ecs_task_definition.main : key => task_def.family
  }
}

output "task_definition_revisions" {
  description = "Revisions of the ECS task definitions"
  value = {
    for key, task_def in aws_ecs_task_definition.main : key => task_def.revision
  }
}

# ====================================================================
# ECS Service Outputs
# ====================================================================
output "service_names" {
  description = "Names of the ECS services"
  value = {
    for key, service in aws_ecs_service.main : key => service.name
  }
}

output "service_arns" {
  description = "ARNs of the ECS services"
  value = {
    for key, service in aws_ecs_service.main : key => service.id
  }
}

output "service_cluster_arns" {
  description = "Cluster ARNs of the ECS services"
  value = {
    for key, service in aws_ecs_service.main : key => service.cluster
  }
}

# ====================================================================
# Load Balancer Outputs
# ====================================================================
output "load_balancer_arns" {
  description = "ARNs of the Application Load Balancers"
  value = {
    for key, alb in aws_lb.main : key => alb.arn
  }
}

output "load_balancer_dns_names" {
  description = "DNS names of the Application Load Balancers"
  value = {
    for key, alb in aws_lb.main : key => alb.dns_name
  }
}

output "load_balancer_zone_ids" {
  description = "Zone IDs of the Application Load Balancers"
  value = {
    for key, alb in aws_lb.main : key => alb.zone_id
  }
}

output "target_group_arns" {
  description = "ARNs of the ALB target groups"
  value = {
    for key, tg in aws_lb_target_group.main : key => tg.arn
  }
}

# ====================================================================
# Security Group Outputs
# ====================================================================
output "alb_security_group_ids" {
  description = "IDs of the ALB security groups"
  value = {
    for key, sg in aws_security_group.alb : key => sg.id
  }
}

output "ecs_security_group_ids" {
  description = "IDs of the ECS security groups"
  value = {
    for key, sg in aws_security_group.ecs : key => sg.id
  }
}

# ====================================================================
# IAM Role Outputs
# ====================================================================
output "task_role_arns" {
  description = "ARNs of the ECS task roles"
  value = {
    for key, role in aws_iam_role.task_role : key => role.arn
  }
}

output "task_role_names" {
  description = "Names of the ECS task roles"
  value = {
    for key, role in aws_iam_role.task_role : key => role.name
  }
}

# ====================================================================
# CloudWatch Outputs
# ====================================================================
output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value = {
    for key, log_group in aws_cloudwatch_log_group.service_logs : key => log_group.name
  }
}

output "log_group_arns" {
  description = "ARNs of the CloudWatch log groups"
  value = {
    for key, log_group in aws_cloudwatch_log_group.service_logs : key => log_group.arn
  }
}

# ====================================================================
# Service Discovery Outputs
# ====================================================================
output "service_discovery_service_arns" {
  description = "ARNs of the service discovery services"
  value = {
    for key, sd_service in aws_service_discovery_service.main : key => sd_service.arn
  }
}

output "service_discovery_service_ids" {
  description = "IDs of the service discovery services"
  value = {
    for key, sd_service in aws_service_discovery_service.main : key => sd_service.id
  }
}

# ====================================================================
# Route53 Outputs
# ====================================================================
output "route53_record_names" {
  description = "Names of the Route53 records created"
  value = {
    for key, record in aws_route53_record.main : key => record.name
  }
}

output "route53_record_fqdns" {
  description = "FQDNs of the Route53 records created"
  value = {
    for key, record in aws_route53_record.main : key => record.fqdn
  }
}

# ====================================================================
# Auto Scaling Outputs
# ====================================================================
output "autoscaling_target_resource_ids" {
  description = "Resource IDs of the auto scaling targets"
  value = {
    for key, target in aws_appautoscaling_target.ecs_target : key => target.resource_id
  }
}

# ====================================================================
# Service URLs and Endpoints
# ====================================================================
output "service_endpoints" {
  description = "Service endpoints (ALB DNS names or custom domains)"
  value = {
    for key, service in var.services : key => {
      http_endpoint  = service.enable_load_balancer ? "http://${aws_lb.main[key].dns_name}" : null
      https_endpoint = service.enable_load_balancer && (service.certificate_arn != null || var.default_certificate_arn != "") ? "https://${aws_lb.main[key].dns_name}" : null
      custom_domain  = service.domain_name != null && var.route53_zone_id != "" ? "https://${service.domain_name}" : null
      alb_dns_name   = service.enable_load_balancer ? aws_lb.main[key].dns_name : null
    }
    if service.enable_load_balancer
  }
}

# ====================================================================
# Service Configuration Summary
# ====================================================================
output "services_summary" {
  description = "Summary of all services created"
  value = {
    for key, service in var.services : key => {
      # Basic configuration
      family            = service.family
      image             = service.image
      cpu               = service.cpu
      memory            = service.memory
      desired_count     = service.desired_count
      container_port    = service.container_port

      # Status
      service_enabled   = service.enable_service
      lb_enabled        = service.enable_load_balancer
      autoscaling_enabled = service.enable_autoscaling
      service_discovery_enabled = service.enable_service_discovery

      # Endpoints
      alb_dns_name      = service.enable_load_balancer ? aws_lb.main[key].dns_name : null
      custom_domain     = service.domain_name

      # Resources created
      task_definition_arn = aws_ecs_task_definition.main[key].arn
      service_arn        = service.enable_service ? aws_ecs_service.main[key].id : null
      alb_arn           = service.enable_load_balancer ? aws_lb.main[key].arn : null
      target_group_arn  = service.enable_load_balancer ? aws_lb_target_group.main[key].arn : null
      log_group_name    = aws_cloudwatch_log_group.service_logs[key].name
    }
  }
}

# ====================================================================
# Health Check and Monitoring URLs
# ====================================================================
output "health_check_urls" {
  description = "Health check URLs for each service"
  value = {
    for key, service in var.services : key => service.enable_load_balancer ? "http://${aws_lb.main[key].dns_name}${service.health_check_path}" : null
    if service.enable_load_balancer
  }
}

# ====================================================================
# Container Information
# ====================================================================
output "container_definitions" {
  description = "Container definitions summary"
  value = {
    for key, service in var.services : key => {
      image          = service.image
      container_port = service.container_port
      cpu            = service.cpu
      memory         = service.memory
      environment_vars_count = length(service.environment_variables)
      secrets_count  = length(service.secrets)
      log_group      = aws_cloudwatch_log_group.service_logs[key].name
    }
  }
}