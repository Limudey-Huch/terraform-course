# Guide — Watching State Locking (DynamoDB) in Action

A hands-on exercise to understand the role of the `terraform-state-locking` table. Requires **two separate SSH connections** to the VM (two terminals).

## Quick Background
When Terraform runs `apply`/`destroy` (not a plain `plan`), it writes a single record to DynamoDB containing `LockID` (the state path), `Who`, and `Operation` — and deletes it when done. This is what protects against two people writing to the same state at the same time.

**Prerequisite**: the backend must already be migrated to S3 (i.e., you've already gone through the process in `aws-backend`, or you're working on `web-app`, which is already configured with a remote backend).

---

## Step 1 — Confirm the table is empty (normal state)

In terminal 1:
```bash
aws dynamodb scan --table-name terraform-state-locking
```
👀 **Expected**: `"Items": []` — empty, since no `apply` is currently running.

## Step 2 — Start a long-running `apply`

Work on `web-app` (it has RDS there, which takes a few minutes — enough time to catch the lock):

In terminal 1:
```bash
cd ~/00_devops_course_iccp/terraform/03-basics/web-app
terraform apply
```
Confirm with `yes` and leave it running.

## Step 3 — Catch the lock "mid-air" from a second terminal

**While** the apply in terminal 1 is still running, in terminal 2 (a separate SSH connection to the same VM):
```bash
aws dynamodb scan --table-name terraform-state-locking
```
👀 **Expected**: this time `Items` is not empty — you'll see one row with fields like `LockID`, `Who` (the user/machine), and `Operation`.

💡 If it comes back empty — try again faster (the apply may have already finished). You can also run a scan in a loop to catch the moment:
```bash
for i in {1..30}; do
  aws dynamodb scan --table-name terraform-state-locking --query 'Count' --output text
  sleep 2
done
```
👀 You'll see `0` most of the time, and `1` for a brief moment or a few seconds while the apply is writing to the state.

## Step 4 — Try running a second `apply` at the same time (optional, for the brave)

While the first one is still running, open a **third terminal** and try:
```bash
cd ~/00_devops_course_iccp/terraform/03-basics/web-app
terraform plan
```
👀 **Expected**: an `Error acquiring the state lock` error — with details on who holds the lock and when it was created. This is exactly the mechanism that prevents corruption when working as a team.

## Step 5 — After the apply finishes

In terminal 1, wait for the `apply` to finish (`Apply complete!`), then in terminal 2:
```bash
aws dynamodb scan --table-name terraform-state-locking
```
👀 **Expected**: back to `"Items": []` — the lock was released automatically.

---

## Comprehension Question
Why does the lock need to live in DynamoDB (or a similar mechanism) instead of just a "flag file" inside the S3 bucket itself?
<details>
<summary>Hint</summary>
S3 (in older versions) didn't support atomic conditional writes ("write only if it doesn't already exist") — without that, two processes could both "think" they'd grabbed the lock at the same time. DynamoDB supports this natively. (Newer versions of Terraform do allow locking directly through S3 — that's exactly the `use_lockfile` setting from the deprecation warning we saw earlier.)
</details>
