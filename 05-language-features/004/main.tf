terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "bucket_suffix" {
  description = "שנו ערך זה כדי לגרום להחלפת ה-bucket (force replacement)"
  type        = string
  default     = "v1"
}

resource "aws_s3_bucket" "lab" {
  bucket_prefix = "lab-05-004-${var.bucket_suffix}-"
  force_destroy = true

  # create_before_destroy: ביצירת תחליף, Terraform יצור קודם את החדש,
  # ורק אחרי שהוא קיים - ימחק את הישן. בלי זה, ברירת המחדל היא ההפך
  # (קודם destroy, אחר כך create) - יש רגע שבו שום bucket לא קיים.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "lab-lifecycle-demo"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.lab.bucket
}
