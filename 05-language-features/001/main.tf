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

variable "bucket_count" {
  description = "כמה buckets ליצור"
  type        = number
  default     = 3
}

resource "aws_s3_bucket" "lab" {
  count         = var.bucket_count
  bucket_prefix = "lab-05-001-${count.index}-"
  force_destroy = true

  tags = {
    Name  = "lab-bucket-${count.index}"
    Index = count.index
  }
}

output "bucket_names" {
  value = aws_s3_bucket.lab[*].bucket
}
