terraform {
  backend "s3" {
    bucket = "REPLACE-WITH-YOUR-BUCKET-NAME"
    key    = "09-developer-workflows/bootstrap-oidc/terraform.tfstate"
    region = "eu-north-1"
    # שימוש ב-native S3 locking (לא DynamoDB) - התכונה החדשה שראינו כ-warning
    # ב-03-basics, במקום dynamodb_table.
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

# ---------- OIDC Provider ----------
# מחבר בין AWS ל-GitHub Actions. יש לחשבון AWS מותר רק ספק OIDC אחד
# לכל URL - אם כבר קיים אחד בחשבון, ה-apply הזה ייכשל עם "already exists"
# ואפשר פשוט למחוק את הבלוק הזה ולהשתמש ב-data source במקום.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # Thumbprint של ה-root CA (כרגע ISRG Root X1 - Let's Encrypt) ששירת את
  # token.actions.githubusercontent.com. ווידאתי את זה ישירות מול השרת
  # (לא מהזיכרון!) כי GitHub כבר החליפו CA בעבר, וערך ישן לא יעבוד.
  # הערה: AWS בפועל כבר לא אוכף את הבדיקה הזו לספקים מוכרים כמו GitHub,
  # אבל ה-resource עדיין דורש ערך תקין מבחינת syntax.
  thumbprint_list = [
    "ab9d0263244dd0326eb67015705a667e79cfe998",
  ]
}

# ---------- IAM Role ----------
# התפקיד ש-GitHub Actions "ילבש" זמנית - בלי שום access key קבוע.
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-ci-lab09"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # מגביל את מי שיכול "ללבוש" את התפקיד הזה - רק ה-repo הספציפי שלכם,
          # מכל branch/PR/tag (ה-* בסוף). אפשר להדק עוד יותר ל-"ref:refs/heads/main" בלבד.
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# ---------- הרשאות ----------
# לצורך ה-lab: גישה מלאה ל-S3 (זה כל מה שה-app/ מנהל) + יכולת לקרוא/לכתוב
# state בעצמו. בפרויקט אמיתי הייתם מצמצמים את זה למשאבים ספציפיים בלבד.
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

output "role_arn" {
  description = "הכניסו את זה ל-.github/workflows/terraform.yml בשדה role-to-assume"
  value       = aws_iam_role.github_actions.arn
}
