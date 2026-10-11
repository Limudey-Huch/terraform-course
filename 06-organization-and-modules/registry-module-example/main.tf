terraform {
  # Assumes s3 bucket and dynamo DB table already set up
  # See /code/03-basics/aws-backend
  backend "s3" {
    bucket         = "REPLACE-WITH-YOUR-BUCKET-NAME"
    key            = "06-organization-and-modules/registry-module-example/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # הערה: מודול זה (s3-bucket v5.x) דורש provider חדש משמעותית מ-~> 3.0
      # שבו משתמש שאר הקורס - זו דוגמה אמיתית לקונפליקט גרסאות שקורה
      # כשתלויים במודול חיצוני. התיקון כאן תקף רק ל-example הזה (root module
      # עצמאי, לא משותף עם שום דבר אחר בקורס).
      version = ">= 6.42.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

############################################################
##
## דוגמה לשימוש במודול מוכן מה-Terraform Registry (לא מ-git ישיר)
## מודול זה מתוחזק באופן פעיל ע"י קהילת terraform-aws-modules:
## https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws
##
############################################################
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket_prefix = "lab-06-registry-module-"
  force_destroy = true

  versioning = {
    enabled = true
  }
}

output "bucket_id" {
  value = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}
