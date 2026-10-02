locals {
  oidc_provider_url_without_scheme = replace(var.oidc_provider_url, "https://", "")
}

resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowServiceAccountAssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          (var.condition_operator) = {
            "${local.oidc_provider_url_without_scheme}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_url_without_scheme}:sub" = var.service_account_subjects
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = var.role_name
    Role = var.role_purpose
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}