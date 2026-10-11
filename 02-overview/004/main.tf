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

variable "db_pass" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "example" {
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "postgres"
  engine_version      = "12"
  instance_class      = "db.t3.micro"
  name                = "labdb"
  username            = "labuser"
  password            = var.db_pass
  skip_final_snapshot = true

  tags = {
    Name = "lab-004-db"
  }
}

output "db_endpoint" {
  value = aws_db_instance.example.endpoint
}
