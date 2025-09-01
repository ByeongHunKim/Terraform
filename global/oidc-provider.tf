resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  url = "https://app.terraform.io"
  client_id_list = [
    "aws.workload.identity"
  ]
  tags = {
    Name         = "terraform-cloud-oidc"
    Environment  = "dev"
    Organization = "Meiko_Org"
  }
}

data "aws_iam_policy_document" "terraform_cloud_trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.terraform_cloud.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }
    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = [
        "organization:Meiko_Org:project:default:workspace:Meiko:run_phase:*"
      ]
    }
  }
}

resource "aws_iam_role" "terraform_cloud" {
  name               = "tfc-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.terraform_cloud_trust.json
  tags = {
    Name        = "tfc-oidc-role"
    Purpose     = "terraform cloud OIDC federated role"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "administrator_access" {
  role       = aws_iam_role.terraform_cloud.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
