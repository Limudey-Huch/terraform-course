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

variable "environments" {
  description = "שמות הסביבות שלכל אחת ייווצר bucket"
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}

resource "aws_s3_bucket" "lab" {
  for_each      = var.environments
  bucket_prefix = "lab-05-002-${each.value}-"
  force_destroy = true

  tags = {
    Name        = "lab-bucket-${each.value}"
    Environment = each.value
  }
}

output "bucket_names" {
  value = { for env, bucket in aws_s3_bucket.lab : env => bucket.bucket }
}
