# ====================================================================
# Terraform Cloud OIDC Provider
# - Creates OIDC identity provider for Terraform Cloud
# ====================================================================
resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  url = var.oidc_url

  client_id_list = [
    var.audience
  ]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-oidc-provider"
  })
}

# ====================================================================
# IAM Trust Policy Document
# - Defines trust relationship for Terraform Cloud workspace
# ====================================================================
data "aws_iam_policy_document" "terraform_cloud_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.terraform_cloud.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:aud"
      values   = [var.audience]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:sub"
      values = [
        "organization:${var.terraform_cloud_organization}:project:${var.terraform_cloud_project}:workspace:${var.workspace_name}:run_phase:*"
      ]
    }
  }
}

# ====================================================================
# IAM Role for Terraform Cloud
# - Role that Terraform Cloud will assume
# ====================================================================
resource "aws_iam_role" "terraform_cloud" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_cloud_trust.json

  tags = merge(var.tags, {
    Name    = var.role_name
    Purpose = "Terraform Cloud OIDC federated role"
  })
}

# ====================================================================
# IAM Role Policy Attachments
# - Attach specified policies to the role
# ====================================================================
resource "aws_iam_role_policy_attachment" "terraform_cloud_policies" {
  count = length(var.policy_arns)

  role       = aws_iam_role.terraform_cloud.name
  policy_arn = var.policy_arns[count.index]
}