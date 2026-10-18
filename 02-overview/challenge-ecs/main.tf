# Challenge: ECS Fargate + ALB + RDS
# Follow README.md. Write your code under the heading of each step.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "name_prefix" {
  description = "Short name in English (lowercase letters, digits and hyphens only, up to 12 characters)"
  type        = string
}

variable "db_pass" {
  description = "RDS master password (at least 8 characters)"
  type        = string
  sensitive   = true
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------- Step 1: Security Groups (C2) ----------
# TODO: alb-sg, ecs-sg, rds-sg


# ---------- Step 2: ECR, Cluster, IAM, Log group (C1) ----------
# TODO: aws_ecr_repository, aws_ecs_cluster, aws_iam_role + policy, aws_cloudwatch_log_group


# ---------- Step 3: RDS (C5) ----------
# TODO: aws_db_instance


# ---------- Step 4: Load Balancer (C3) ----------
# TODO: aws_lb, aws_lb_target_group, aws_lb_listener


# ---------- Step 5: Task definition and Service (C4, C6, C7, C8) ----------
# TODO: aws_ecs_task_definition, aws_ecs_service, tags, outputs
