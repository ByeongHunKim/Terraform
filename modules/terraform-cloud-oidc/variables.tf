# ====================================================================
# Terraform Cloud OIDC Module Variables
# ====================================================================
variable "terraform_cloud_organization" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "terraform_cloud_project" {
  description = "Terraform Cloud project name"
  type        = string
  default     = "default"
}

variable "workspace_name" {
  description = "Terraform Cloud workspace name"
  type        = string
}

variable "oidc_url" {
  description = "Terraform Cloud OIDC URL"
  type        = string
  default     = "https://app.terraform.io"
}

variable "audience" {
  description = "OIDC audience"
  type        = string
  default     = "aws.workload.identity"
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "tfc-oidc-role"
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