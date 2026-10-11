## 02 - Overview + Setup

## Install Terraform

Official installation instructions from HashiCorp: https://learn.hashicorp.com/tutorials/terraform/install-cli

## AWS Account Setup

AWS Terraform provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication

1) create non-root AWS user
2) Add the necessary IAM roles (e.g. AmazonEC2FullAccess)
3) Save Access key + secret key (or use AWS CLI `aws configure` -- https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## תרגילים — בניית טופולוגיה שלב-אחר-שלב

כל תרגיל מתבסס על קריאה בתיעוד הרשמי של [Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs), ובונה על התרגיל הקודם:

| # | תרגיל | משאב(ים) חדשים |
|---|-------|-----------------|
| [001](001/README.md) | EC2 Instance | `aws_instance` |
| [002](002/README.md) | + Security Group | `aws_security_group` |
| [003](003/README.md) | + Load Balancer | `aws_lb`, `aws_lb_target_group`, `aws_lb_listener`, `aws_subnets` (data) |
| [004](004/README.md) | RDS Database (standalone) | `aws_db_instance` |
| [005](005/README.md) | **טופולוגיה סופית**: EC2 + LB + RDS | שילוב של כל הקודם, עם שרשרת Security Groups מלאה |

כל תיקייה היא Terraform root module עצמאי — `cd` לתיקייה, `terraform init`, ולהמשיך לפי ההוראות ב-README שלה.
