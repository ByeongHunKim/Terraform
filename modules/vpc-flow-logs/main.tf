# ====================================================================
# VPC Flow Logs Module - CloudWatch Logging
# ====================================================================

# ====================================================================
# CloudWatch Log Group - VPC Flow Logs
# ====================================================================
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = var.log_group_name != "" ? var.log_group_name : "/aws/vpc/flow-logs/${var.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name    = var.log_group_name != "" ? var.log_group_name : "/aws/vpc/flow-logs/${var.name_prefix}"
    Type    = "CloudWatch Log Group"
    Purpose = "VPC Flow Logs"
  })
}

# ====================================================================
# IAM Role
# ====================================================================
resource "aws_iam_role" "flow_logs" {
  name               = var.iam_role_name != "" ? var.iam_role_name : "${var.name_prefix}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name    = var.iam_role_name != "" ? var.iam_role_name : "${var.name_prefix}-vpc-flow-logs-role"
    Type    = "IAM Role"
    Purpose = "VPC Flow Logs"
  })
}

# ====================================================================
# IAM Trust Policy
# ====================================================================
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ====================================================================
# IAM Policy
# ====================================================================
data "aws_iam_policy_document" "flow_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      aws_cloudwatch_log_group.flow_logs.arn,
      "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    ]
  }
}

# ====================================================================
# IAM Role Policy Attachment
# ====================================================================
resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.name_prefix}-vpc-flow-logs-policy"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_policy.json
}

# ====================================================================
# VPC Flow Log
# ====================================================================
resource "aws_flow_log" "main" {
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type             = var.traffic_type
  vpc_id                   = var.vpc_id
  log_format               = var.log_format
  max_aggregation_interval = var.max_aggregation_interval

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-flow-log"
    Type    = "VPC Flow Log"
    Purpose = "Network Traffic Logging"
  })
}