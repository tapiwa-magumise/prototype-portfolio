# GitHub Actions deploys with OIDC; there are no stored AWS keys.
# The OIDC provider already exists in the account (shared with other projects).
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "deploy" {
  name = "${var.name}-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

# Upload site files and clear the cache. Nothing else.
resource "aws_iam_role_policy" "deploy" {
  name = "deploy"
  role = aws_iam_role.deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "s3:ListBucket", Resource = aws_s3_bucket.site.arn },
      { Effect = "Allow", Action = ["s3:PutObject", "s3:DeleteObject"], Resource = "${aws_s3_bucket.site.arn}/*" },
      { Effect = "Allow", Action = "cloudfront:CreateInvalidation", Resource = aws_cloudfront_distribution.site.arn },
    ]
  })
}
