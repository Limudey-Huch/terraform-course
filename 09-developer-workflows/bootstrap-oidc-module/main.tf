terraform {
  backend "s3" {
    bucket       = "REPLACE-WITH-YOUR-BUCKET-NAME"
    key          = "09-developer-workflows/bootstrap-oidc-module/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "github_org" {
  description = "שם המשתמש/ארגון ב-GitHub"
  type        = string
}

variable "github_repo" {
  description = "שם הריפו (בלי ה-org)"
  type        = string
}

############################################################
##
## אותה תוצאה בדיוק כמו ב-bootstrap-oidc/ (hand-rolled),
## הפעם דרך מודול מוכן ומתוחזק: philips-labs/github-oidc/aws
## 1.1M+ downloads - https://registry.terraform.io/modules/philips-labs/github-oidc/aws
##
############################################################

module "oidc_provider" {
  source = "github.com/philips-labs/terraform-aws-github-oidc//modules/provider?ref=v0.8.1"

  # הערה אמיתית שגילינו תוך כדי בדיקה: ה-thumbprint שה-default של המודול
  # מגדיר (6938fd4d98bab03faadb97b34396831e3780aea1) הוא בדיוק הערך הישן
  # והלא-מעודכן שכבר ראינו ב-bootstrap-oidc/ ותיקנו שם! גם מודול עם מיליון+
  # הורדות יכול לשאת default מיושן. ה-override כאן משתמש בערך שאימתנו בעצמנו
  # ישירות מול השרת.
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

module "oidc_role" {
  source = "github.com/philips-labs/terraform-aws-github-oidc?ref=v0.8.1"

  openid_connect_provider_arn = module.oidc_provider.openid_connect_provider.arn
  repo                        = "${var.github_org}/${var.github_repo}"
  role_name                   = "github-actions-terraform-ci-lab09-module"

  # ברירת המחדל של המודול כבר מחמירה יותר ממה שכתבנו ידנית ב-bootstrap-oidc/:
  # allow_main (רק branch main) + deny_pull_request (חוסם PRs במפורש).
  # בקוד שלנו הגבלנו רק ל-"כל branch/PR/tag בריפו" - פחות מדויק.
  default_conditions = ["allow_main", "deny_pull_request"]

  role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}

output "role_arn" {
  description = "הכניסו את זה ל-.github/workflows/terraform.yml בשדה role-to-assume"
  value       = module.oidc_role.role.arn
}
