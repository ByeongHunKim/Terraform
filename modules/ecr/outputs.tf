# ====================================================================
# ECR Module Outputs
# ====================================================================

# ====================================================================
# Repository Information
# ====================================================================
output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for key, repo in aws_ecr_repository.main : key => repo.arn
  }
}

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for key, repo in aws_ecr_repository.main : key => repo.repository_url
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for key, repo in aws_ecr_repository.main : key => repo.name
  }
}

output "repository_registry_ids" {
  description = "Registry IDs of the ECR repositories"
  value = {
    for key, repo in aws_ecr_repository.main : key => repo.registry_id
  }
}

# ====================================================================
# Service-specific Image URIs
# ====================================================================
output "image_uris" {
  description = "Complete image URIs for each service (without tag)"
  value = {
    for key, repo in aws_ecr_repository.main : key => "${repo.repository_url}"
  }
}

output "image_uris_with_latest" {
  description = "Complete image URIs with 'latest' tag"
  value = {
    for key, repo in aws_ecr_repository.main : key => "${repo.repository_url}:latest"
  }
}

# ====================================================================
# Registry Information
# ====================================================================
output "registry_id" {
  description = "Registry ID (AWS Account ID)"
  value       = values(aws_ecr_repository.main)[0].registry_id
}

output "repository_count" {
  description = "Number of repositories created"
  value       = length(aws_ecr_repository.main)
}

# ====================================================================
# Docker Commands for Reference
# ====================================================================
output "docker_login_command" {
  description = "AWS CLI command to login to ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${values(aws_ecr_repository.main)[0].registry_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

output "docker_build_push_commands" {
  description = "Docker commands to build and push images for each service"
  value = {
    for key, repo in aws_ecr_repository.main : key => {
      build = "docker build -t ${key} ."
      tag   = "docker tag ${key}:latest ${repo.repository_url}:latest"
      push  = "docker push ${repo.repository_url}:latest"
    }
  }
}

# ====================================================================
# Development Helper Outputs
# ====================================================================
output "service_image_map" {
  description = "Map of service names to their ECR image URIs (for use in terraform.tfvars)"
  value = {
    for key, repo in aws_ecr_repository.main : key => "${repo.repository_url}:latest"
  }
}

# ====================================================================
# Data Sources
# ====================================================================
data "aws_region" "current" {}