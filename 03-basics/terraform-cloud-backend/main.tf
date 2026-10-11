terraform {
  backend "remote" {
    organization = "devops-directive"

    workspaces {
      name = "devops-directive-terraform-course"
    }
  }

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
