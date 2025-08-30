# ====================================================================
# Terraform Configuration - Version and Provider Requirements
# - Terraform version constraint
# - AWS provider configuration
# - Backend configuration moved to separate file
# ====================================================================
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95.0"
    }
  }
}

# ====================================================================
# AWS Provider Configuration - Development Environment
# - Region configuration
# - Default tags for all resources
# ====================================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}