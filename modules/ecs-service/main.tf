# ====================================================================
# ECS Service Module - Task Definitions and Services
# - Creates multiple ECS services using for_each
# - Includes ALB, Security Groups, and CloudWatch Logging
# ====================================================================

# ====================================================================
# Data Sources
# ====================================================================
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ====================================================================
# CloudWatch Log Groups - One per service
# ====================================================================
resource "aws_cloudwatch_log_group" "service_logs" {
  for_each = var.services

  name              = "/ecs/${var.name_prefix}/${each.key}"
  retention_in_days = each.value.log_retention_days

  tags = merge(var.tags, {
    Name        = "/ecs/${var.name_prefix}/${each.key}"
    Service     = each.key
    Type        = "CloudWatch Log Group"
    Purpose     = "ECS Service Logs"
  })
}

# ====================================================================
# ECS Task Roles - Application-level permissions
# ====================================================================
resource "aws_iam_role" "task_role" {
  for_each = var.services

  name = "${var.name_prefix}-${each.key}-task-role"

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
    Name    = "${var.name_prefix}-${each.key}-task-role"
    Service = each.key
    Type    = "IAM Role"
    Purpose = "ECS Task Role"
  })
}

# ====================================================================
# Basic Task Role Policy - CloudWatch Logs access
# ====================================================================
resource "aws_iam_role_policy" "task_role_logs" {
  for_each = var.services

  name = "${var.name_prefix}-${each.key}-logs"
  role = aws_iam_role.task_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.service_logs[each.key].arn}:*"
      }
    ]
  })
}

# ====================================================================
# ECS Task Definitions
# ====================================================================
resource "aws_ecs_task_definition" "main" {
  for_each = var.services

  family                   = each.value.family
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = tostring(each.value.cpu)
  memory                  = tostring(each.value.memory)
  execution_role_arn      = var.execution_role_arn
  task_role_arn          = aws_iam_role.task_role[each.key].arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = each.value.essential

      # Port configuration
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.host_port != null ? each.value.host_port : each.value.container_port
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        for key, value in each.value.environment_variables : {
          name  = key
          value = value
        }
      ]

      # Secrets from Parameter Store or Secrets Manager
      secrets = [
        for key, value in each.value.secrets : {
          name      = key
          valueFrom = value
        }
      ]

      # Logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service_logs[each.key].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      # Optional configurations
      command          = each.value.command
      entryPoint       = each.value.entrypoint
      workingDirectory = each.value.working_directory

      # Health check (basic)
      healthCheck = {
        command = ["CMD-SHELL", "exit 0"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name    = each.value.family
    Service = each.key
    Type    = "ECS Task Definition"
    Purpose = "Container Definition"
  })
}

# ====================================================================
# Security Groups - ALB Security Groups
# ====================================================================
resource "aws_security_group" "alb" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_load_balancer
  }

  name_prefix = "${var.name_prefix}-${each.key}-alb-"
  vpc_id      = var.vpc_id

  # HTTP inbound
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS inbound
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}-alb-sg"
    Service = each.key
    Type    = "Security Group"
    Purpose = "ALB Security Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ====================================================================
# Security Groups - ECS Security Groups
# ====================================================================
resource "aws_security_group" "ecs" {
  for_each = var.services

  name_prefix = "${var.name_prefix}-${each.key}-ecs-"
  vpc_id      = var.vpc_id

  # Allow inbound from ALB
  dynamic "ingress" {
    for_each = each.value.enable_load_balancer ? [1] : []
    content {
      from_port       = each.value.container_port
      to_port         = each.value.container_port
      protocol        = "tcp"
      security_groups = [aws_security_group.alb[each.key].id]
    }
  }

  # Additional custom security group rules
  dynamic "ingress" {
    for_each = merge(var.default_security_group_rules, each.value.security_group_rules)
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      security_groups = ingress.value.source_security_group_id != null ? [ingress.value.source_security_group_id] : null
    }
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}-ecs-sg"
    Service = each.key
    Type    = "Security Group"
    Purpose = "ECS Task Security Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ====================================================================
# Application Load Balancers
# ====================================================================
resource "aws_lb" "main" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_load_balancer
  }

  name               = substr("${replace(var.name_prefix, "-", "")}-${each.key}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[each.key].id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}-alb"
    Service = each.key
    Type    = "Application Load Balancer"
    Purpose = "Load Balancing"
  })
}

# ====================================================================
# ALB Target Groups
# ====================================================================
resource "aws_lb_target_group" "main" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_load_balancer
  }

  name        = substr("${replace(var.name_prefix, "-", "")}-${each.key}-tg", 0, 32)
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = each.value.health_check_matcher
    path                = each.value.health_check_path
    port                = each.value.health_check_port
    protocol            = each.value.health_check_protocol
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}-tg"
    Service = each.key
    Type    = "ALB Target Group"
    Purpose = "Load Balancer Target Group"
  })
}

# ====================================================================
# ALB Listeners - HTTP (redirect to HTTPS)
# ====================================================================
resource "aws_lb_listener" "http" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_load_balancer
  }

  load_balancer_arn = aws_lb.main[each.key].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}-http-listener"
    Service = each.key
  })
}

# ====================================================================
# ALB Listeners - HTTPS
# ====================================================================
resource "aws_lb_listener" "https" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_load_balancer && (service.certificate_arn != null || var.default_certificate_arn != "")
  }

  load_balancer_arn = aws_lb.main[each.key].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = each.value.certificate_arn != null ? each.value.certificate_arn : var.default_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.key].arn
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}-https-listener"
    Service = each.key
  })
}

# ====================================================================
# ECS Services
# ====================================================================
resource "aws_ecs_service" "main" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_service
  }

  name            = each.key
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.main[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"
  platform_version = var.platform_version

  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  deployment_maximum_percent        = each.value.deployment_maximum_percent

  network_configuration {
    security_groups  = [aws_security_group.ecs[each.key].id]
    subnets         = var.public_subnet_ids // temp : private_subnet_ids
    assign_public_ip = true //temp : each.value.assign_public_ip
  }

  # Load balancer configuration
  dynamic "load_balancer" {
    for_each = each.value.enable_load_balancer ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.main[each.key].arn
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  # Service discovery configuration
  dynamic "service_registries" {
    for_each = each.value.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.main[each.key].arn
    }
  }

  enable_execute_command = each.value.enable_execute_command

  tags = merge(var.tags, {
    Name    = each.key
    Service = each.key
    Type    = "ECS Service"
    Purpose = "Container Service"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.https
  ]
}

# ====================================================================
# Service Discovery Services (Optional)
# ====================================================================
resource "aws_service_discovery_service" "main" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_service_discovery && service.service_discovery_namespace_id != null
  }

  name = each.key

  dns_config {
    namespace_id = each.value.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = merge(var.tags, {
    Name    = each.key
    Service = each.key
    Type    = "Service Discovery"
    Purpose = "Internal Service Discovery"
  })
}

# ====================================================================
# Route53 Records (Optional)
# ====================================================================
resource "aws_route53_record" "main" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_load_balancer && service.domain_name != null && var.route53_zone_id != ""
  }

  zone_id = var.route53_zone_id
  name    = each.value.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main[each.key].dns_name
    zone_id                = aws_lb.main[each.key].zone_id
    evaluate_target_health = true
  }
}

# ====================================================================
# Auto Scaling Target (Optional)
# ====================================================================
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_autoscaling
  }

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ====================================================================
# Auto Scaling Policy - CPU
# ====================================================================
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_autoscaling
  }

  name               = "${each.key}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = each.value.target_cpu_utilization
  }
}

# ====================================================================
# Auto Scaling Policy - Memory
# ====================================================================
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  for_each = {
    for key, service in var.services : key => service
    if service.enable_autoscaling
  }

  name               = "${each.key}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = each.value.target_memory_utilization
  }
}