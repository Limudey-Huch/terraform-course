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

resource "aws_instance" "example" {
  ami           = "ami-01637463b2cbe7cb6" # Ubuntu 20.04 LTS // eu-north-1
  instance_type = "t3.micro"
}
