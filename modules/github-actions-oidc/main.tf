# ====================================================================
# GitHub Actions OIDC Provider
# - Creates OIDC identity provider for GitHub Actions
# ====================================================================
resource "aws_iam_openid_connect_provider" "github_actions" {
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
# ====================================================================
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:aud"
      values   = [var.audience]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_url, "https://", "")}:sub"
      values = [
        "repo:${var.github_organization}/${var.repository_name}:*",
        "repo:${var.github_organization}/${var.repository_name}:ref:refs/heads/*",
        "repo:${var.github_organization}/${var.repository_name}:ref:refs/pull/*",
        "repo:${var.github_organization}/${var.repository_name}:pull_request"
      ]
    }
  }
}

# ====================================================================
# IAM Role for GitHub Actions
# - Role that GitHub Actions will assume
# ====================================================================
resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = merge(var.tags, {
    Name    = var.role_name
    Purpose = "GitHub Actions OIDC federated role"
  })
}

# ====================================================================
# IAM Role Policy Attachments
# - Attach specified policies to the role
# ====================================================================
resource "aws_iam_role_policy_attachment" "github_actions_policies" {
  count = length(var.policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = var.policy_arns[count.index]
}