# ====================================================================
# GitHub Actions OIDC Module Variables
# ====================================================================
variable "github_organization" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_project" {
  description = "GitHub project name (wildcarded in trust policy)"
  type        = string
  default     = "*"
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "oidc_url" {
  description = "GitHub Actions OIDC URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "audience" {
  description = "OIDC audience"
  type        = string
  default     = "sts.amazonaws.com"
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "github-actions-oidc-role"
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}