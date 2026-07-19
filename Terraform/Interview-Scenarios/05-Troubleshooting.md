# 🎤 Troubleshooting Real Errors
**11 Slides · 8 Real Error Messages + Debugging Toolkit + Q&A**

---

# 🔴 Slide 1 · Scenario: "Error acquiring the state lock"

**🏗️ Setup**
> *A plan or apply fails immediately with a lock error showing a lock ID, a timestamp, and the owner.*

**❓ The Question**
You see this error — walk me through your diagnosis.

```
│ Error: Error acquiring the state lock
│ Lock Info:
│   ID:        abc-123-def
│   Operation: OperationTypeApply
│   Who:       ci@build-server-1
│   Created:   2024-01-15 14:32:00
```

**🔍 Diagnosis**
1. Is the process still running? Check CI for job matching lock ID `abc-123-def`
2. Is the timestamp recent? If 10+ minutes ago with no matching CI job → safely stuck
3. Inspect the DynamoDB lock record to confirm who owns it

**✅ Fix**
```bash
# Step 1: Confirm what's in the lock record
aws dynamodb get-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"my-bucket/prod/terraform.tfstate"}}'

# Step 2: After confirming the process is dead
terraform force-unlock abc-123-def  # ← use the ID from the error message

# Step 3: Check for partial state from mid-apply crash
terraform plan
```

**🛡️ Prevention**
- Always run Terraform from CI, not developer laptops
- Set generous CI job timeouts so locks release automatically on failure

> ⚠️ **Never:** Delete the DynamoDB item directly — and never force-unlock while another apply IS actually running, or you will corrupt state

---

# 🔴 Slide 2 · Scenario: "Provider produced inconsistent result"

**🏗️ Setup**
> *Apply succeeds partially then errors with a provider inconsistency message on a security group rule.*

**❓ The Question**
What causes this and how do you fix it?

```
│ Error: Provider produced inconsistent result after apply
│ When applying changes to aws_security_group_rule.ingress, provider
│ "registry.terraform.io/hashicorp/aws" produced an unexpected new value
```

**🔍 Diagnosis**
1. Check if provider computed a value differently than planned (common with AWS-managed tags, timestamps)
2. Check for race condition in AWS eventual consistency (SG rule propagation delay)
3. Check for Terraform version mismatch between plan job and apply job in CI

**✅ Fix**
```hcl
# Fix: ignore AWS-managed tags that change after apply
resource "aws_security_group_rule" "ingress" {
  lifecycle {
    ignore_changes = [tags["LastModified"]]  # ← ignore AWS-managed tag
  }
}
```

```bash
# If transient: retry the apply — eventual consistency errors often self-resolve
terraform apply

# If persistent: check provider version
terraform providers  # ← shows exact provider version in use
```

**🛡️ Prevention**
- Re-run the apply first before adding `ignore_changes` — most are transient
- Pin provider versions to avoid behavior changes on unexpected upgrades

> ⚠️ **Never:** Add broad `ignore_changes = all` to silence this error — you will miss real configuration drift going forward

---

# 🔴 Slide 3 · Scenario: "Error: Invalid function argument"

**🏗️ Setup**
> *A plan fails on a `toset()` call with a type conversion error.*

**❓ The Question**
What causes this type error and how do you fix it?

```
│ Error: Invalid function argument
│ Call to function "toset" failed: cannot convert tuple to set of strings:
│ element 0: string required, got number.
```

**🔍 Diagnosis**
1. The list passed to `toset()` contains mixed types — Terraform sets are homogeneous
2. Convert all elements to the same type before calling `toset()`

**✅ Fix**
```hcl
locals {
  bad  = toset([1, "a", 2])                      # ← ERROR: mixed number + string

  good = toset([tostring(1), "a", tostring(2)])  # ← convert numbers to strings first

  # Bulk-convert a variable with formatlist
  ids  = formatlist("%s", var.raw_ids)            # ← ensures all elements are strings
}
```

**🛡️ Prevention**
- Define typed variables (`type = list(string)`) to catch type mismatches at input time
- Avoid mixing numeric IDs and string IDs in the same list

> ⚠️ **Never:** Cast the whole list to `list(any)` to silence the error — this delays the type problem to a later stage and is harder to debug

---

# 🔴 Slide 4 · Scenario: "Error: Cycle"

**🏗️ Setup**
> *A plan fails with a dependency cycle error between two resources.*

**❓ The Question**
How do you diagnose and break a circular dependency?

```
│ Error: Cycle: aws_security_group.app, aws_security_group_rule.self
```

**🔍 Diagnosis**
1. Identify which resources are in the cycle
2. Determine if it's self-referencing (SG referencing itself) or mutual (A→B, B→A)
3. Break the cycle by separating one direction into a distinct resource

**✅ Fix**
```hcl
# SOLUTION: separate the self-referencing rule into its own resource
resource "aws_security_group" "app" {
  name = "app"
  # No inline ingress/egress referencing self
}

resource "aws_security_group_rule" "self_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id  # ← safe: separate resource
  security_group_id        = aws_security_group.app.id
}
```

```bash
# Visualize the full dependency graph
terraform graph | dot -Tpng > graph.png  # ← requires graphviz
```

**🛡️ Prevention**
- Prefer `aws_security_group_rule` resources over inline blocks for any SG-to-SG references
- Run `terraform graph` early when designing complex resource relationships

> ⚠️ **Never:** Use `depends_on` to try to resolve cycles — it controls ordering, not direction, and won't fix a true cycle

---

# 🔴 Slide 5 · Scenario: "EntityAlreadyExists"

**🏗️ Setup**
> *An apply fails because a resource exists in AWS but is absent from Terraform state.*

**❓ The Question**
What caused this and what is the exact fix?

```
│ Error: Error creating IAM Role: EntityAlreadyExists:
│ Role with name terraform-role already exists.
```

**🔍 Diagnosis**
1. Resource was created manually in the console, or state was accidentally deleted
2. Terraform has no record of the resource, so it tries to create it fresh
3. Fix: import the existing resource into state

**✅ Fix**
```bash
# Import the existing resource into Terraform state
terraform import aws_iam_role.terraform "terraform-role"
# ← "terraform-role" is the existing role name in AWS

# Verify: plan must show zero changes after import
terraform plan  # ← if changes appear, align HCL with real resource attributes
```

**🛡️ Prevention**
- Use IAM SCPs to prevent manual resource creation in managed accounts
- Run scheduled `terraform plan -refresh-only` in CI to detect drift early

> ⚠️ **Never:** Delete the existing resource and let Terraform recreate it — for IAM roles this breaks all existing trust relationships and attached policies

---

# 🔴 Slide 6 · Scenario: Plan Shows Unexpected Destroy + Create

**🏗️ Setup**
> *A plan shows `-/+ destroy and then create replacement` on an RDS instance because you renamed the identifier.*

**❓ The Question**
How do you prevent the DB from being destroyed when you need to rename it?

```
-/+ destroy and then create replacement
  aws_db_instance.main
  ~ identifier = "old-name" -> "new-name"  # forces replacement
```

**🔍 Diagnosis**
1. Some RDS attributes force replacement when changed — `identifier` is one of them
2. `prevent_destroy` blocks the apply entirely — use when you want an error rather than a destroy
3. `create_before_destroy` creates the new resource first — use when you must rename

**✅ Fix**
```hcl
# Option 1: prevent_destroy — apply errors before destroying (safest for prod DBs)
resource "aws_db_instance" "main" {
  lifecycle {
    prevent_destroy = true
  }
}

# Option 2: create_before_destroy — new instance before old is deleted
resource "aws_db_instance" "main" {
  lifecycle {
    create_before_destroy = true
  }
  # Use a randomized suffix to avoid identifier collision during transition
  identifier = "${var.name}-${random_id.suffix.hex}"
}
```

**🛡️ Prevention**
- Set `prevent_destroy = true` on all prod stateful resources
- Review every plan that contains `forces replacement` before approving

> ⚠️ **Never:** Remove `prevent_destroy` and re-apply without carefully reviewing the plan — the next apply after removing the guard may contain an unintended destroy

---

# 🔴 Slide 7 · Scenario: Terraform Plan Timeout / API Throttling

**🏗️ Setup**
> *Plan takes 20+ minutes and eventually fails. AWS API calls are being throttled.*

**❓ The Question**
How do you diagnose and fix Terraform plan timeouts caused by AWS API throttling?

**🔍 Diagnosis**
1. Enable DEBUG logging to see throttling messages from AWS
2. Identify whether it's specific resources or broad throttling across the account
3. Tune provider retry behavior and reduce parallelism

**✅ Fix**
```bash
# Step 1: Enable debug logging to see throttling
TF_LOG=DEBUG terraform plan 2>&1 | grep "Throttling\|rate limit\|RetryAttempt"

# Step 2: Reduce parallelism to make fewer concurrent API calls
terraform plan -parallelism=5   # ← default is 10

# Step 3: Skip refresh if state is known-good
terraform plan -refresh=false   # ← pair with nightly refresh-only runs
```

```hcl
# Step 4: Tune provider retry behavior
provider "aws" {
  retry_mode  = "adaptive"  # ← auto backs off on throttle responses
  max_retries = 15           # ← default is 10
}
```

**🛡️ Prevention**
- Split large state files — fewer resources per state = fewer API calls per plan
- Run scheduled `terraform plan -refresh-only` nightly instead of refreshing every CI run

> ⚠️ **Never:** Use `-refresh=false` as your permanent default — you will miss real drift; use it in CI for speed only

---

# 🔴 Slide 8 · Scenario: "Missing required argument"

**🏗️ Setup**
> *A plan fails immediately because a required variable was not provided via any input method.*

**❓ The Question**
How do you diagnose what's missing and provide the value correctly?

```
│ Error: Missing required argument
│ The argument "key_name" is required
```

**🔍 Diagnosis**
1. Variable has no default and was not provided via tfvars, env var, or `-var` flag
2. Check whether the variable should have a default or must always be explicitly set

**✅ Fix**
```bash
# Option 1: pass on the command line
terraform plan -var="key_name=my-key"

# Option 2: add to terraform.tfvars (auto-loaded)
echo 'key_name = "my-key"' >> terraform.tfvars

# Option 3: environment variable
export TF_VAR_key_name="my-key"
```

```hcl
# Option 4: add a default if the variable is truly optional
variable "key_name" {
  type    = string
  default = null  # ← null means "not provided" — only if resource accepts null
}
```

**🛡️ Prevention**
- Document all required variables in a `variables.tf` with descriptions
- Provide a `terraform.tfvars.example` committed to the repo showing all required values

> ⚠️ **Never:** Add a default of `""` (empty string) when `null` is more appropriate — some resources treat empty string as a valid value rather than "not set"

---

# 🔴 Slide 9 · Debugging Toolkit

**❓ The Question**
What debugging tools do you reach for when Terraform behaves unexpectedly?

**✅ Fix**
```bash
# Log levels: TRACE > DEBUG > INFO > WARN > ERROR
TF_LOG=DEBUG terraform plan          # ← verbose: shows all provider API calls
TF_LOG=INFO terraform plan           # ← less verbose, usually enough
TF_LOG_PATH=./terraform.log terraform plan  # ← write to file instead of stderr

# Trace provider API calls specifically
TF_LOG=TRACE terraform apply 2>&1 | grep "Request\|Response"

# Validate config syntax without touching remote state
terraform validate

# Check which provider versions are loaded
terraform providers

# See full resource attributes including computed ones
terraform state show aws_instance.web

# Visualize dependency graph
terraform graph | dot -Tpng > graph.png  # ← requires graphviz
```

> ⚠️ **Never:** Leave `TF_LOG=TRACE` enabled in CI — it logs sensitive API responses including secret values, and produces gigabytes of output that overwhelms log aggregators

---

# 🎤 Slide 10 · Follow-up Q&A

---

### Q: How do you find which resource is causing a slow plan?
- Enable `TF_LOG=JSON` and grep for `Refreshing state...` lines with timestamps
- Each line shows which resource is being refreshed and how long it takes
- Common culprits: resources with many tags, resources in high-latency regions, large S3 bucket policies
- Fix options: `ignore_changes` on slow-returning fields, move slow resources to a separate state file, use `-refresh=false` with scheduled refresh-only plans

> 💬 **Say:** "JSON logging gives you per-resource timing. Without it you're guessing which of 500 resources is the bottleneck."

---

### Q: `terraform apply` succeeded but the resource doesn't have the configuration you expected. What do you check?
1. Was `ignore_changes` set? Check all `lifecycle` blocks in the resource and its module
2. Did a provisioner run, but the change happens post-boot — `user_data` runs only on first boot
3. Is the attribute being set by a separate resource? (e.g., `aws_security_group_rule` vs inline rules — only one wins)
4. Is there an eventual consistency delay? Wait 30–60 seconds and re-check
5. Did you apply a saved plan that was stale? Re-plan from scratch
6. Check CloudTrail — did another system or person change the resource after Terraform applied?

> 💬 **Say:** "Start with CloudTrail — it shows the complete history of who changed what and when, which immediately narrows down whether Terraform, another process, or a person made the unexpected change."

---
