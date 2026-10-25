# Run ONCE, by hand, from your own machine (never from CI).
# Creates everything the pipeline needs before it can run:
#   1. an S3 bucket for the Terraform state (CI runners are throw-away, they cannot keep a local state file)
#   2. a trust relationship between GitHub Actions and AWS (OIDC)
#   3. an IAM role that GitHub Actions assumes, with temporary credentials

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "github_org" {
  description = "GitHub user or organization that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for every name. Lowercase letters, digits and hyphens"
  type        = string
}

variable "create_oidc_provider" {
  description = "Set to false if the account already has the GitHub OIDC provider (only one is allowed per account)"
  type        = bool
  default     = true
}

data "aws_caller_identity" "current" {}

# ---------- State bucket ----------
resource "aws_s3_bucket" "state" {
  bucket        = "${var.name_prefix}-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- GitHub OIDC ----------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_role" "github_actions" {
  name = "${var.name_prefix}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        # only workflows of THIS repo can assume the role
        # two patterns: the old format (repo:org/repo) and the new one (repo:org@ID/repo@ID)
        # that GitHub sends when the repo uses an immutable subject (the default for new repos)
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_org}/${var.github_repo}:*",
            "repo:${var.github_org}@*/${var.github_repo}@*:*",
          ]
        }
      }
    }]
  })
}

# Lab permissions: PowerUser covers Lambda, API Gateway, DynamoDB and S3.
# PowerUser has no IAM, so IAM is granted separately and ONLY for roles that start with the prefix.
resource "aws_iam_role_policy_attachment" "power_user" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy" "iam_for_app_roles" {
  name = "manage-app-roles"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iam:*"
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*"
    }]
  })
}

output "role_arn" {
  description = "GitHub repo variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "state_bucket" {
  description = "GitHub repo variable TF_STATE_BUCKET"
  value       = aws_s3_bucket.state.bucket
}
