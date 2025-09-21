# ====================================================================
# ECR Module - Container Image Registry
# - Creates ECR repositories for container images
# - Includes lifecycle policies for cost optimization
# - Security features: image scanning, encryption
# ====================================================================

# ====================================================================
# ECR Repositories - One for each service
# ====================================================================
resource "aws_ecr_repository" "main" {
  for_each = var.repositories

  name                 = "${var.name_prefix}/${each.key}"
  image_tag_mutability = each.value.image_tag_mutability

  # Image scanning configuration
  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  # Encryption configuration
  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key        = each.value.kms_key_id
  }

  # Force delete
  force_delete = each.value.force_delete

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}/${each.key}"
    Service     = each.key
    Type        = "ECR Repository"
    Purpose     = "Container Image Registry"
    Environment = var.environment
  })
}

# ====================================================================
# ECR Lifecycle Policies - Image cleanup for cost optimization
# ====================================================================
resource "aws_ecr_lifecycle_policy" "main" {
  for_each = {
    for key, repo in var.repositories : key => repo
    if repo.lifecycle_policy_enabled
  }

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      # Rule 1: Keep only latest N tagged images
      {
        rulePriority = 1
        description  = "Keep last ${each.value.keep_last_images} tagged images"
        selection = {
          tagStatus     = "tagged"
          countType     = "imageCountMoreThan"
          countNumber   = each.value.keep_last_images
        }
        action = {
          type = "expire"
        }
      },
      # Rule 2: Delete untagged images older than N days
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${each.value.untagged_expire_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = each.value.untagged_expire_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ====================================================================
# ECR Repository Policies - Access control
# ====================================================================
resource "aws_ecr_repository_policy" "main" {
  for_each = {
    for key, repo in var.repositories : key => repo
    if length(repo.allowed_principals) > 0
  }

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullPush"
        Effect = "Allow"
        Principal = {
          AWS = each.value.allowed_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchDeleteImage"
        ]
      }
    ]
  })
}