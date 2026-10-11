terraform {
  backend "s3" {
    bucket       = "REPLACE-WITH-YOUR-BUCKET-NAME"
    key          = "09-developer-workflows/app/terraform.tfstate"
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

# משאב מכוון לפשטות - המטרה של התרגיל היא לראות את ה-pipeline עובד,
# לא ללמוד עוד סוג משאב. זול ומהיר ליצור/למחוק.
resource "aws_s3_bucket" "app_data" {
  bucket_prefix = "lab-09-cicd-"
  force_destroy = true

  tags = {
    ManagedBy = "github-actions"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app_data.bucket
}
