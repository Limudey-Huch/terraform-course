# Terraform with AWS — Comprehensive Summary

## What is Terraform?

Terraform is an open-source **Infrastructure as Code (IaC)** tool created by HashiCorp. It allows you to define, provision, and manage cloud infrastructure using a declarative configuration language called **HCL (HashiCorp Configuration Language)**.

Instead of manually clicking through the AWS Console or writing imperative scripts, you describe *what* your infrastructure should look like, and Terraform figures out *how* to make it happen.

---

## Why Use Terraform with AWS?

### The Problem Without IaC
- Manual infrastructure setup is slow, error-prone, and hard to reproduce
- No version control for infrastructure changes
- Difficult to maintain consistency across environments (dev, staging, production)
- No easy way to roll back changes
- Knowledge lives in people's heads, not in code

### What Terraform Solves

| Benefit | Description |
|---|---|
| **Reproducibility** | Same config always produces the same infrastructure |
| **Version Control** | Store `.tf` files in Git — track every change |
| **Automation** | CI/CD pipelines can apply infrastructure changes automatically |
| **Multi-Cloud** | Same tool works with AWS, Azure, GCP, and 3000+ providers |
| **State Management** | Terraform tracks what exists and only changes what's needed |
| **Collaboration** | Teams can review infrastructure changes via pull requests |
| **Cost Visibility** | See what will be created/destroyed before applying |
| **Dependency Management** | Terraform understands resource dependencies and creates them in the right order |

---

## Core Concepts

### Provider
The plugin that lets Terraform interact with AWS APIs.

```hcl
provider "aws" {
  region  = "eu-north-1"
  profile = "my-aws-profile"
}
```

### Resource
A single piece of infrastructure (EC2 instance, S3 bucket, VPC, etc.).

```hcl
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "MyWebServer"
  }
}
```

### Data Source
Read existing infrastructure that Terraform doesn't manage.

```hcl
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

### Variables
Parameterize your configuration for reuse.

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
```

### Outputs
Expose values after infrastructure is created.

```hcl
output "instance_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
}
```

### State File
Terraform keeps a `terraform.tfstate` file that maps your config to real AWS resources. This is how it knows what exists and what needs to change.

### Modules
Reusable, self-contained packages of Terraform configuration.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}
```

---

## Essential Terraform Commands

### Workflow Commands (Daily Use)

| Command | Purpose | When to Use |
|---|---|---|
| `terraform init` | Initialize working directory, download providers & modules | First time setup, or after adding new providers/modules |
| `terraform plan` | Preview what changes Terraform will make | Before every apply — always review the plan |
| `terraform apply` | Execute the changes and create/update/destroy resources | After reviewing the plan |
| `terraform destroy` | Tear down all managed infrastructure | When you want to delete everything |

### Detailed Command Breakdown

#### `terraform init`
```bash
terraform init
```
- Downloads the AWS provider plugin
- Downloads any modules referenced in your config
- Initializes the backend (where state is stored)
- Must be run once per project, or when providers/modules change

#### `terraform plan`
```bash
terraform plan                          # Basic plan
terraform plan -out=tfplan              # Save plan to file
terraform plan -var="environment=prod"  # Pass variables
terraform plan -target=aws_instance.web # Plan for specific resource only
```
- Shows a diff of what will be created (+), changed (~), or destroyed (-)
- Does NOT make any changes — purely informational
- Always run before `apply`

#### `terraform apply`
```bash
terraform apply                  # Apply with confirmation prompt
terraform apply tfplan           # Apply a saved plan (no prompt)
terraform apply -auto-approve    # Skip confirmation (use in CI/CD)
terraform apply -var-file="prod.tfvars"  # Use variable file
```
- Actually creates/updates/destroys AWS resources
- Shows the plan first and asks for confirmation (unless `-auto-approve`)

#### `terraform destroy`
```bash
terraform destroy                           # Destroy everything
terraform destroy -target=aws_instance.web  # Destroy specific resource
terraform destroy -auto-approve             # Skip confirmation
```
- Removes all resources managed by Terraform
- Use `-target` to destroy specific resources only

### State Management Commands

| Command | Purpose |
|---|---|
| `terraform state list` | List all resources in the state |
| `terraform state show <resource>` | Show details of a specific resource |
| `terraform state mv <source> <dest>` | Rename/move a resource in state |
| `terraform state rm <resource>` | Remove a resource from state (without destroying it) |
| `terraform state pull` | Download remote state to stdout |
| `terraform state push` | Upload local state to remote backend |

```bash
# Examples
terraform state list
# aws_instance.web_server
# aws_s3_bucket.data
# aws_vpc.main

terraform state show aws_instance.web_server
# Shows all attributes of the instance

terraform state rm aws_instance.web_server
# Terraform "forgets" about this resource (it still exists in AWS)
```

### Other Useful Commands

| Command | Purpose |
|---|---|
| `terraform fmt` | Auto-format `.tf` files to standard style |
| `terraform validate` | Check syntax and configuration validity |
| `terraform output` | Display output values |
| `terraform refresh` | Update state to match real infrastructure |
| `terraform import <resource> <id>` | Import existing AWS resource into Terraform |
| `terraform workspace list` | List workspaces |
| `terraform workspace new <name>` | Create a new workspace |
| `terraform graph` | Generate a visual dependency graph |
| `terraform taint <resource>` | Mark resource for recreation on next apply |
| `terraform console` | Interactive console for testing expressions |

---

## Common AWS Resources in Terraform

### Networking

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "main-vpc" }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "main-igw" }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Security Group
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Compute (EC2)

```hcl
resource "aws_instance" "app" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name        = "app-server"
    Environment = var.environment
  }
}
```

### Storage (S3)

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-company-data-bucket"

  tags = { Environment = var.environment }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
```

### Database (RDS)

```hcl
resource "aws_db_instance" "postgres" {
  identifier             = "app-database"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  skip_final_snapshot     = false
  final_snapshot_identifier = "app-db-final-snapshot"

  tags = { Environment = var.environment }
}
```

### IAM

```hcl
resource "aws_iam_role" "ec2_role" {
  name = "ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-app-profile"
  role = aws_iam_role.ec2_role.name
}
```

### Load Balancer (ALB)

```hcl
resource "aws_lb" "app" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

---

## Remote State (Best Practice)

Never store state locally in production. Use S3 + DynamoDB for remote state with locking.

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

```hcl
# Create the state bucket and lock table (run this first, separately)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## Typical Project Structure

```
project/
├── main.tf           # Primary resources
├── variables.tf      # Variable declarations
├── outputs.tf        # Output declarations
├── providers.tf      # Provider configuration
├── backend.tf        # Remote state configuration
├── terraform.tfvars  # Variable values (DON'T commit secrets)
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

---

## The Standard Terraform Workflow

```
1. Write      →  Define infrastructure in .tf files
2. Init       →  terraform init
3. Plan       →  terraform plan (review changes)
4. Apply      →  terraform apply (create resources)
5. Iterate    →  Modify .tf files → plan → apply
6. Destroy    →  terraform destroy (when done)
```

---

## Key Best Practices

1. **Always run `terraform plan` before `apply`** — never apply blindly
2. **Use remote state** with S3 + DynamoDB for team collaboration and locking
3. **Never commit secrets** — use `terraform.tfvars` in `.gitignore`, or use AWS Secrets Manager
4. **Use modules** to avoid code duplication
5. **Tag everything** — makes cost tracking and resource management easier
6. **Use workspaces or separate state files** per environment (dev/staging/prod)
7. **Pin provider versions** to avoid unexpected breaking changes
8. **Enable state file encryption** at rest
9. **Use `lifecycle` blocks** to prevent accidental destruction of critical resources
10. **Run `terraform fmt`** and `terraform validate` in CI pipelines

---

## Terraform vs AWS CloudFormation

| Feature | Terraform | CloudFormation |
|---|---|---|
| Language | HCL (readable, concise) | JSON/YAML (verbose) |
| Multi-Cloud | Yes (AWS, Azure, GCP, etc.) | AWS only |
| State | Managed by you (S3 + DynamoDB) | Managed by AWS |
| Community | Huge ecosystem of modules | AWS-maintained |
| Drift Detection | `terraform plan` / `refresh` | Built-in drift detection |
| Speed | Generally faster | Can be slower for large stacks |
| Learning Curve | Moderate | Moderate |
| Import Existing | `terraform import` | Import supported |

---

## Quick Reference Cheat Sheet

```bash
# Setup
terraform init                    # Initialize project
terraform init -upgrade           # Upgrade providers

# Development
terraform fmt                     # Format code
terraform validate                # Validate config
terraform console                 # Interactive testing

# Deployment
terraform plan                    # Preview changes
terraform plan -out=tfplan        # Save plan
terraform apply tfplan            # Apply saved plan
terraform apply -auto-approve     # Apply without prompt

# Inspection
terraform show                    # Show current state
terraform output                  # Show outputs
terraform state list              # List all resources
terraform state show <resource>   # Show resource details

# Maintenance
terraform refresh                 # Sync state with reality
terraform import <res> <id>       # Import existing resource
terraform taint <resource>        # Force recreation

# Cleanup
terraform destroy                 # Destroy all resources
terraform destroy -target=<res>   # Destroy specific resource

# Workspaces
terraform workspace list          # List workspaces
terraform workspace new dev       # Create workspace
terraform workspace select dev    # Switch workspace
```
