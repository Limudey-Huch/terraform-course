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

variable "environment" {
  description = "שם הסביבה"
  type        = string
  default     = "dev"
}

variable "team_members" {
  description = "רשימת חברי הצוות"
  type        = list(string)
  default     = ["eyal", "dana", "noa"]
}

locals {
  # Conditional expression (ternary) - condition ? true_val : false_val
  is_prod        = var.environment == "prod"
  retention_days = local.is_prod ? 30 : 3

  # String functions
  team_csv = join(", ", var.team_members)

  # For expression - טרנספורמציה של רשימה שלמה בשורה אחת
  team_upper = [for name in var.team_members : upper(name)]
}

resource "aws_s3_bucket" "lab" {
  bucket_prefix = "lab-05-003-${lower(var.environment)}-"
  force_destroy = true

  tags = {
    Environment     = upper(var.environment)
    RetentionDays   = local.retention_days
    Team            = local.team_csv
    TeamMemberCount = length(var.team_members)
  }
}

output "team_upper" {
  value = local.team_upper
}

output "is_prod" {
  value = local.is_prod
}
