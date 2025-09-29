# ====================================================================
# VPC Flow Logs Module Variables
# ====================================================================

# ====================================================================
# Required Variables
# ====================================================================
variable "vpc_id" {
  description = "VPC ID to enable flow logs"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

# ====================================================================
# CloudWatch Log Group Configuration
# ====================================================================
variable "log_group_name" {
  description = "Name of the CloudWatch log group (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "CloudWatch log group retention period in days"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_in_days)
    error_message = "Log retention period must be a valid CloudWatch Logs retention value."
  }
}

# ====================================================================
# IAM Role Configuration
# ====================================================================
variable "iam_role_name" {
  description = "Name of the IAM role for VPC Flow Logs (if empty, auto-generated)"
  type        = string
  default     = ""
}

# ====================================================================
# Flow Log Configuration
# ====================================================================
variable "traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "Traffic type must be one of: ACCEPT, REJECT, ALL."
  }
}

variable "log_format" {
  description = "Custom log format for flow logs (null for default format)"
  type        = string
  default     = null
}

variable "max_aggregation_interval" {
  description = "Maximum interval of time during which a flow is captured and aggregated (60 or 600 seconds)"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.max_aggregation_interval)
    error_message = "Max aggregation interval must be either 60 or 600 seconds."
  }
}

# ====================================================================
# Tagging
# ====================================================================
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}