# Challenge — ECS Fargate + ALB + RDS

A capstone exercise for `02-overview`. There is no solution and no check script. Build the infrastructure with Terraform so that every **contract** below is true. How you get there is up to you.

> The nginx app does not actually talk to the DB. The point is to wire the infrastructure and the network correctly.

## Topology

```
                    Internet
                       |  :80
                 +-----v-----+
                 |    ALB    |   alb-sg
                 +-----+-----+
                       |  :80   (target type = ip)
        +--------------v--------------+
        | ECS Service (Fargate x 2)   |   ecs-sg
        | task: nginx                 |---> CloudWatch Logs
        +--------------+--------------+
                       |  :5432
                 +-----v-----+
                 | RDS       |   rds-sg
                 | Postgres  |   (not public)
                 +-----------+

   ECR repo (empty for now)         IAM role: task execution
```

**Familiar from 005**: the Security Group chain, ALB + target group + listener, RDS, `sensitive` variables, data sources, outputs. Open `../005/main.tf` as a starting point.

**New**: ECR repository, ECS cluster, task definition, ECS service, IAM role, CloudWatch log group.

## Ground rules

- Region `eu-north-1`, the **default** VPC and subnets, **no NAT Gateway**.
- AWS provider `~> 5.0`. Docs: [Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).
- Two variables: `name_prefix` (lowercase letters, digits and hyphens, up to 12 characters) and `db_pass` (`sensitive`, at least 8 characters, **never in the code**).
- Container image: `public.ecr.aws/docker/library/nginx:latest`.
- Names, all built from `name_prefix`:

| Resource | Name |
|---|---|
| ECR repository | `<name_prefix>-app` |
| Security Groups | `<name_prefix>-alb-sg`, `<name_prefix>-ecs-sg`, `<name_prefix>-rds-sg` |
| Load Balancer / Target Group | `<name_prefix>-alb` / `<name_prefix>-tg` |
| ECS cluster / service | `<name_prefix>-cluster` / `<name_prefix>-service` |
| Log group | `/ecs/<name_prefix>` |
| RDS identifier | `<name_prefix>-db` |

Run with: `terraform apply -var="name_prefix=<name>" -var="db_pass=<password>"` (or `export TF_VAR_db_pass='...'`).

## Contracts

| # | Contract |
|---|---|
| C1 | ECR repo with `scan_on_push` enabled and `IMMUTABLE` tags |
| C2 | `alb-sg` allows 80 from the internet. `ecs-sg` allows 80 **only** from `alb-sg` (a reference to the SG, not a CIDR) and has egress to the outside. `rds-sg` allows 5432 **only** from `ecs-sg` |
| C3 | Application Load Balancer with a listener on 80 forwarding to a target group: `target_type = ip`, port 80, health check on `/` with matcher 200. Both targets become `healthy` |
| C4 | ECS cluster. Task definition: FARGATE, `awsvpc`, 256 CPU / 512 MB, container on port 80, logs to `/ecs/<name_prefix>`. Service: FARGATE, `desired_count = 2`, in the default VPC subnets with `ecs-sg`, attached to the target group |
| C5 | RDS: Postgres 16, `db.t3.micro`, 20GB, `publicly_accessible = false`, attached only to `rds-sg`, password from a variable |
| C6 | Every resource that supports tags has `Project = "ecs-challenge"` and `Owner = <name_prefix>` |
| C7 | Outputs: `alb_dns_name`, `ecr_repository_url`, `db_endpoint` |
| C8 | `http://<alb_dns_name>/` returns HTTP 200 |

## Steps

Work in order. After each step run `terraform apply` and make sure the contract works before moving on.

### Step 1 — Security Groups (C2)

Pitfalls:
- **An SG name starting with `sg-`** is rejected by AWS. That is why the names end with `-sg`.
- **No `egress` block on `ecs-sg`**: Terraform removes the default "allow all outbound" rule. The damage only appears in step 5 (the task cannot pull its image or ship logs).
- Open to another SG with `security_groups = [...]`, not `cidr_blocks`.

### Step 2 — ECR, Cluster, IAM, Log group (C1)

Pitfalls:
- **ECR repo names must be lowercase.**
- **IAM role names are unique per account.** Include `name_prefix`.
- **The execution role needs two things**: a trust policy for `ecs-tasks.amazonaws.com`, and the managed policy `AmazonECSTaskExecutionRolePolicy`. No separate task role is needed.
- **Create the log group in Terraform**, or the task stops with "log group does not exist".
- **`force_delete = true` on the ECR repo**, so `destroy` works even if images were pushed.

### Step 3 — RDS (C5)

RDS takes about 5 minutes. Apply this step early and keep coding while it is created.

Pitfalls:
- **`db_name`, not `name`**: older examples (including `../005`) use `name`. On `Unsupported argument`, check the docs for the current argument name.
- **`skip_final_snapshot = true`**, or `destroy` fails.
- **Set `vpc_security_group_ids`**, or the DB gets the VPC default SG instead of `rds-sg`.
- **A password shorter than 8 characters** is rejected.

### Step 4 — Load Balancer (C3)

The target group stays empty until step 5. That is expected.

Pitfalls:
- **`target_type = "ip"`**. The default (`instance`) does not work with Fargate, and the error only appears in step 5.
- **An ALB needs at least 2 subnets in different AZs.**
- **Names**: up to 32 characters, letters, digits and hyphens, no hyphen at the start or end.
- **The health check must match the container**: nginx answers 200 on `/` on port 80. Otherwise you get 502 or 503.

### Step 5 — Task definition and Service (C4, C6, C7, C8)

Pitfalls:
- **An invalid `cpu`/`memory` pair.** With 256 CPU, memory must be 512, 1024 or 2048.
- **`container_definitions` is JSON.** Use `jsonencode(...)`.
- **Names must match**: `container_name` and `container_port` in the service's `load_balancer` block must equal the container's `name` and `containerPort`.
- **The service is created before the listener**: the error says the target group "does not have an associated load balancer".

  <details>
  <summary>Hint</summary>

  `depends_on` forces creation order even without a direct reference. We cover it in module 05.
  </details>

- **`assign_public_ip = true`.** Without a NAT, the task needs a public IP to pull its image, otherwise you get `CannotPullContainerError`.
- **Tags on everything (C6)**:

  <details>
  <summary>Hint</summary>

  `default_tags` in the `provider "aws"` block applies tags to every resource that supports them.
  </details>

- **Wait 1 to 3 minutes after `apply`** for the targets to become `healthy`.

## When a task does not come up

ECS Console → your cluster → your service → **Events**, then **Tasks** → Stopped → the reason.

| What you see | Where to look |
|---|---|
| `CannotPullContainerError` / timeout | `assign_public_ip`, egress on `ecs-sg`, the image name |
| `ResourceInitializationError` | the execution role and its policy, the log group |
| Targets stay `unhealthy` | health check port and path, `ecs-sg` allowing 80 from `alb-sg` |
| 503 from the ALB | no healthy targets yet |
| The service is not created | `target_type`, creation order versus the listener, container names |

## Cleanup

```bash
terraform destroy -var="name_prefix=<name>" -var="db_pass=<password>"
```

Takes 5 to 10 minutes. Run it at the end of the class: ECS, the ALB and RDS cost money as long as they exist.
