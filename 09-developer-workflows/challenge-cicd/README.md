# Challenge — CI/CD for a Serverless API (Terraform + GitHub Actions + AWS)

A capstone exercise for `09-developer-workflows`. There is no solution and no check script. You write the Terraform **and** the pipeline so that every **contract** below is true. How you get there is up to you.

> Goal: after this exercise, **nobody runs `terraform apply` by hand**. You open a Pull Request, GitHub shows you the plan, you merge, and the infrastructure changes by itself.

Time: about 90 minutes. Cost: a few cents (Lambda, API Gateway and DynamoDB on-demand are almost free at this volume).

## What you are building

```
   Developer                  GitHub                              AWS (eu-north-1)
  +---------+  git push   +----------------------+  OIDC token   +--------------------+
  | laptop  | ----------> | Pull Request         | ------------> | IAM role           |
  +---------+             |  -> job "plan"       |  (temporary,  | (no access keys)   |
                          |     fmt, validate,   |   expires)    +---------+----------+
                          |     plan             |                         |
                          |                      |                         v
                          | merge to main        |             +-----------------------+
                          |  -> job "apply"      | terraform   |  S3: Terraform state  |
                          |     apply            | ----------> +-----------------------+
                          |     smoke test (curl)|
                          +----------------------+

   The infrastructure the pipeline deploys:

     Internet --GET /hello--> API Gateway (HTTP API) --> Lambda (python3.12) --> DynamoDB
                                                              |                  table <prefix>-hits
                                                              +--> CloudWatch Logs
```

**Familiar from before**: Terraform, S3 backend, IAM roles, OIDC and the plan/apply split from `../README.md`.

**New**: Lambda, API Gateway (HTTP API), DynamoDB, a Lambda zip built by Terraform (`archive_file`), a pipeline that you write yourself with a smoke test at the end.

## What is given and what you write

| Path | Who | What |
|---|---|---|
| `bootstrap/main.tf` | **given** | Run **once, by hand**. Creates the state bucket, the GitHub OIDC trust and the IAM role for the pipeline |
| `lambda/handler.py` | **given** | The function code. Each call adds 1 to a counter in DynamoDB and returns JSON. Do not change it |
| `app/` | **you write** | The infrastructure: DynamoDB, IAM, Lambda, API Gateway |
| `.github/workflows/deploy.yml` | **you write** | The pipeline |

## Setup (once)

**1. A separate GitHub repo.** GitHub Actions only reads `.github/workflows/` from the **root of a repo**. Create a new empty repo and make the content of this folder its root:

```bash
mkdir ~/cicd-challenge && cp -r bootstrap lambda app .github .gitignore README.md ~/cicd-challenge/
cd ~/cicd-challenge
git init -b main
git remote add origin https://github.com/<your-user>/<your-repo>.git
```

**2. Bootstrap** (from your machine, uses your AWS CLI credentials):

```bash
cd bootstrap
terraform init
terraform apply -var="github_org=<your-user>" -var="github_repo=<your-repo>" -var="name_prefix=<name>"
```

If it fails with `EntityAlreadyExists` for the OIDC provider, the account already has one. Add `-var="create_oidc_provider=false"`.

**3. Save the two outputs as GitHub repository variables** (repo → Settings → Secrets and variables → Actions → **Variables** tab). These are not secrets, so they are variables:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN` | output `role_arn` |
| `TF_STATE_BUCKET` | output `state_bucket` |
| `NAME_PREFIX` | the same `<name>` you used above |

**Keep the `bootstrap/` folder and its `terraform.tfstate` file.** You need them for the cleanup.

## Ground rules

- Region `eu-north-1`. Terraform `>= 1.10` (the pipeline's Terraform version must support `use_lockfile`).
- AWS provider `~> 5.0`, and the `hashicorp/archive` provider for the zip.
- **No AWS access keys anywhere**: not in the code, not in GitHub Secrets. Only the OIDC role.
- The state lives in the S3 bucket from the bootstrap, key `cicd-challenge/terraform.tfstate`. The `backend "s3" {}` block stays **empty** and the settings are passed with `-backend-config` (so the code has no bucket name in it and works for everyone).
- Variables of `app/`: `name_prefix` (no default) and `app_version` (default `"v1"`).
- Names, all built from `name_prefix`:

| Resource | Name |
|---|---|
| DynamoDB table | `<name_prefix>-hits` |
| Lambda role | `<name_prefix>-lambda-role` |
| Lambda function | `<name_prefix>-fn` |
| Log group | `/aws/lambda/<name_prefix>-fn` |
| API | `<name_prefix>-api` |

> The pipeline role may create IAM roles **only if their name starts with `<name_prefix>-`**. That is why the names above matter.

## Contracts — infrastructure (`app/`)

| # | Contract |
|---|---|
| A1 | DynamoDB table: on-demand billing (`PAY_PER_REQUEST`), hash key `id` of type string |
| A2 | Lambda role: trusts `lambda.amazonaws.com`, has `AWSLambdaBasicExecutionRole`, and an inline policy that allows **only** `dynamodb:UpdateItem` on **that table** (a reference to the table ARN, not `"*"`) |
| A3 | Log group `/aws/lambda/<name_prefix>-fn`, 7 days retention, **created by Terraform** |
| A4 | Lambda: `python3.12`, handler `handler.handler`, code zipped from `../lambda` by `archive_file` (no zip file committed), environment `TABLE_NAME` (from the table resource) and `APP_VERSION` (from the variable) |
| A5 | HTTP API (`protocol_type = "HTTP"`) with a Lambda proxy integration (payload format 2.0), route `GET /hello`, a `$default` stage with `auto_deploy`, and a Lambda permission that lets API Gateway invoke the function |
| A6 | Every resource that supports tags has `Project = "cicd-challenge"` and `Owner = <name_prefix>` |
| A7 | Outputs: `api_url`, `table_name` |
| A8 | `GET <api_url>hello` returns HTTP 200 and JSON with `message` and `hits`. `hits` goes up by 1 on every call |

## Contracts — pipeline (`.github/workflows/deploy.yml`)

| # | Contract |
|---|---|
| P1 | The workflow runs on a `pull_request` to `main` **and** on a `push` to `main`, only when `app/**`, `lambda/**` or the workflow file itself changed |
| P2 | Authentication is OIDC only: `permissions` with `id-token: write`, and `aws-actions/configure-aws-credentials` with `role-to-assume` taken from `vars.AWS_ROLE_ARN`. No access keys |
| P3 | **On a Pull Request**: `terraform fmt -check`, `init`, `validate` and `plan` run, and the plan is visible in the run. **Apply never runs on a Pull Request** |
| P4 | **On a push to `main`**: `init`, `apply -auto-approve`. Apply never runs from any other branch |
| P5 | After the apply there is a **smoke test**: read `api_url` from `terraform output`, call `GET /hello`, and **fail the job** if the answer is not 200 |
| P6 | Two runs never apply at the same time (a `concurrency` group, without cancelling a running apply) |
| P7 | The bucket name, the role ARN and `name_prefix` come from `vars.*`. Nothing account-specific is hard-coded in the workflow |

## Contracts — the whole flow (the real test)

| # | Contract |
|---|---|
| E1 | The first push to `main` creates the whole infrastructure and the smoke test is green |
| E2 | A Pull Request that changes `app_version` from `"v1"` to `"v2"` shows a plan with **1 to change** (the Lambda only), and does not change anything in AWS |
| E3 | After merging that Pull Request, `curl <api_url>hello` answers `hello from v2`, and **you ran no `terraform` command yourself** |
| E4 | A Pull Request with a badly formatted `.tf` file (extra spaces) turns the check **red** and cannot be merged without a fix. After `terraform fmt` it is green again |

## Steps

Work in order. Do not go to the next step before the current one works.

### Step 1 — Write `app/` and test it from your machine (A1–A8)

Write the whole infrastructure, then run it **once locally** to make sure the Terraform itself is good, before involving a pipeline. Debugging Terraform through a pipeline is slow and painful.

```bash
cd app
terraform init -backend-config="bucket=<state_bucket>" -backend-config="key=cicd-challenge/terraform.tfstate" -backend-config="region=eu-north-1" -backend-config="use_lockfile=true"
terraform apply -var="name_prefix=<name>"
curl "$(terraform output -raw api_url)hello"
```

Call it 3 times. `hits` must be 1, 2, 3.

Then **destroy it** (`terraform destroy -var="name_prefix=<name>"`). The pipeline will create it for real in step 3.

Pitfalls:
- **`backend "s3" {}` stays empty.** Everything else goes through `-backend-config`.
- **`api_url` ends with a `/`.** The URL is `.../` and the route is `hello`, so the call is `<api_url>hello`. Writing `<api_url>/hello` gives `//hello` and a 404.
- **No `aws_lambda_permission` = a 500 error** (`Internal Server Error`) from API Gateway, even though the Lambda itself is fine. The source ARN is the API's `execution_arn` followed by `/*/*`.
- **`route_key` is `"GET /hello"`**, with a space. Anything else gives 404 `Not Found`.
- **Payload format version `2.0`.** The handler is written for it.
- **Create the log group in Terraform** (A3), and make the Lambda depend on it. Otherwise Lambda creates its own log group, and `destroy` leaves it behind (it keeps costing, and the next `apply` fails with "already exists").
- **The zip file:** `archive_file` writes `lambda.zip` next to your code. Do not commit it (it is in `.gitignore`). Use `source_code_hash` so a change in `handler.py` actually updates the function.
- **`${path.module}/../lambda`**, not a relative path that depends on where you run Terraform.
- **IAM takes a few seconds to spread.** If the Lambda fails with "The role defined for the function cannot be assumed by Lambda", just run `apply` again.
- **`default_tags`** in the `provider "aws"` block gives you A6 for free.

### Step 2 — A pipeline that only plans (P1, P2, P3, P7)

Write `.github/workflows/deploy.yml` with one job that runs on a Pull Request. Push it to `main` (the workflow must exist on `main` first), then open a Pull Request with any small change.

Useful building blocks (look them up, do not copy blindly):
- `actions/checkout@v4`
- `aws-actions/configure-aws-credentials@v4`
- `hashicorp/setup-terraform@v3` with `terraform_version` and `terraform_wrapper: false`
- Terraform in CI: `-input=false` (never wait for a prompt) and `-no-color` (readable logs)

Pitfalls:
- **`permissions: id-token: write` is mandatory.** Without it the credentials step fails with "Could not load credentials from any providers". Add `contents: read` too, because setting `permissions` removes the defaults.
- **Nothing starts?** For a `pull_request`, GitHub runs the version of the workflow that is in the Pull Request. Check that the Pull Request targets `main`, and that at least one changed file matches the `paths` filter.
- **`Not authorized to perform sts:AssumeRoleWithWebIdentity`**: the `github_org` / `github_repo` you gave to the bootstrap do not match the real repo (case matters), or `AWS_ROLE_ARN` is wrong.
- **Still `Not authorized` and the names are right?** New GitHub repos send the `sub` claim with the org and repo **IDs** (`repo:<org>@<id>/<repo>@<id>:ref:...`). The bootstrap already accepts both formats. If you wrote your own trust policy, add the second pattern. To see what GitHub really sent: CloudTrail → event `AssumeRoleWithWebIdentity` → `userName`.
- **`vars.X` is empty**: you created it as a Secret, or in a different repo. Variables and Secrets are different tabs.
- **`init` asks for a bucket**: the `-backend-config` flags were not passed in CI.
- **The `plan` finds "No changes"** while the infrastructure does not exist: you are not reading the same state. Check the bucket and the `key`.

### Step 3 — Apply on merge (P4, E1)

Add a second job that runs **only** on a push to `main` (an `if:` on the event and the ref, or a separate trigger).

Pitfalls:
- **Do not rely on the `on:` trigger alone.** A `pull_request` and a `push` share the same workflow file, so each job needs its own `if:` condition.
- **Apply does not need a plan file.** `terraform apply -auto-approve` plans again by itself. (Passing a saved plan between jobs is more correct, but needs artifacts. It is a bonus.)
- **State lock:** if a run is cancelled in the middle, the lock file stays. See step 5, and `terraform force-unlock <ID>` (the ID is printed in the error) as a last resort.

After merging, open the **Actions** tab and watch the run. When it finishes, call the API yourself.

### Step 4 — Smoke test (P5)

After the apply, call `/hello` and fail if the answer is not 200.

Pitfalls:
- **`curl` without `--fail` exits 0 on a 404 or 500.** The step would be green while the API is broken. Add `--fail` (or check `%{http_code}`).
- **A brand-new API may need a few seconds.** `--retry 5 --retry-delay 3 --retry-all-errors` makes the test stable.
- **Read the URL from Terraform**, not by copy-paste: `terraform output -raw api_url`. This is why `terraform_wrapper: false` is useful.
- **Prove that the test can fail.** Temporarily change the route to `GET /hi` in a Pull Request, merge, and see the smoke test go red. Then revert.

### Step 5 — Concurrency (P6)

Pitfalls:
- **`cancel-in-progress: true` is dangerous for apply.** Cancelling a running `terraform apply` can leave the state locked and the infrastructure half-built. Use `false`: the second run waits for the first.

### Step 6 — Prove the whole flow (E2, E3, E4)

1. Branch, change `app_version` to `"v2"`, open a Pull Request. Read the plan: exactly **1 to change**. Check in AWS that nothing changed yet (E2).
2. Merge. Wait for the run. `curl <api_url>hello` now says `hello from v2` (E3).
3. New branch, add extra spaces to a `.tf` file, open a Pull Request. The check is red (E4). Run `terraform fmt`, push, the check is green.

## Bonus

- **Show the plan inside the Pull Request**: save the plan output and post it as a comment with `actions/github-script`. The job needs `pull-requests: write`.
- **Block merging until the plan passes**: repo → Settings → Branches → a rule for `main` with "Require status checks".
- **Apply the exact plan you reviewed**: `plan -out=tfplan`, upload it as an artifact, download it in the apply job. Why is that safer?
- **A manual destroy workflow** with `workflow_dispatch`.

## When something does not work

| What you see | Where to look |
|---|---|
| The workflow does not start | the `paths` filter, the branch name, the file is in `.github/workflows/` at the **root** of the repo |
| `Could not load credentials` | `permissions: id-token: write` |
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | org/repo name in the bootstrap, `AWS_ROLE_ARN` |
| `AccessDenied` on an `iam:` action | the role name does not start with `<name_prefix>-` |
| `Error acquiring the state lock` | another run is still going, or a cancelled run left the lock |
| `curl` gives 404 `Not Found` | `route_key`, the `//hello` double slash, the `$default` stage |
| `curl` gives 500 `Internal Server Error` | `aws_lambda_permission`, or open the Lambda log group |
| `curl` gives 200 but `hits` is always 1 | the table was recreated; check `terraform plan` for unexpected replacements |

To read the Lambda logs: AWS Console → CloudWatch → Log groups → `/aws/lambda/<name_prefix>-fn`.

## Questions

1. Why does the plan run on `pull_request` and the apply on `push` to `main`, and not both on the same trigger?
2. What would happen if someone opened a Pull Request from a **fork**? (Look at the `sub` condition in the role's trust policy, and at what secrets and tokens a fork gets.)
3. Why is OIDC better than saving `AWS_ACCESS_KEY_ID` in GitHub Secrets? What exactly does an attacker get if each one leaks?
4. The role has `PowerUserAccess`. Which parts of that would you remove for a real project?
5. Why does the state have to be in S3 and not in a file next to the code? What happens to a local state file on a GitHub runner?
6. What does the smoke test catch that `terraform apply` finishing successfully does not?

## Cleanup

Delete in this order. The bootstrap goes last, because it holds the state bucket and the role.

```bash
cd app
terraform init -reconfigure -backend-config="bucket=<state_bucket>" -backend-config="key=cicd-challenge/terraform.tfstate" -backend-config="region=eu-north-1" -backend-config="use_lockfile=true"
terraform destroy -var="name_prefix=<name>"

cd ../bootstrap
terraform destroy -var="github_org=<your-user>" -var="github_repo=<your-repo>" -var="name_prefix=<name>"
```

If you set `create_oidc_provider=false` in the bootstrap, pass the same value to the destroy.

After the destroy, the pipeline can no longer deploy anything. That is expected. Check in the console that no table, function or API is left.
