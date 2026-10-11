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

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "lab-001-instance"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "AMI ID to launch"
  type        = string
  default     = "ami-01637463b2cbe7cb6" # Ubuntu 20.04 LTS // eu-north-1
}

locals {
  environment = "lab"

  # local שמחשב ערך פעם אחת מתוך משתנים - לשימוש חוזר בכמה מקומות
  common_tags = {
    Name        = var.instance_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = local.common_tags
}
