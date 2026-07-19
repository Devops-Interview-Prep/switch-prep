# 🎤 Terraform State Management
**7 Slides · State Recovery, Locks, Import, Drift, Workspaces**

---

# 🔴 Slide 1 · Scenario: Corrupted State File

**🏗️ Setup**
> *CI pod crashed mid-apply while provisioning 30 RDS instances. Now plan shows 15 instances to create (they exist) and 5 to destroy (they don't).*

**❓ The Question**
Walk me through your exact recovery steps.

**🔍 Diagnosis**
1. Back up current (broken) state immediately before touching anything
2. Check S3 versioning history for the last known-good state version
3. Restore the previous version, then import resources missing from state
4. Verify with a final plan — must show zero changes

**✅ Fix**
```bash
# Step 1: Timestamped backup of broken state
terraform state pull > backup-$(date +%s).tfstate

# Step 2: List S3 versions to find last known-good
aws s3api list-object-versions \
  --bucket my-tf-state \
  --prefix prod/rds/terraform.tfstate

# Step 3: Import each resource absent from state
terraform import aws_db_instance.cluster["db-01"] db-01
```

```hcl
# Terraform 1.5+: import block (preferred — handles all 15 at once)
import {
  to = aws_db_instance.cluster["db-01"]
  id = "db-01"  # ← existing RDS identifier in AWS
}
# terraform plan -generate-config-out=generated.tf
```

**🛡️ Prevention**
- Enable S3 versioning on the state bucket — always
- Use `-parallelism=5` for large resource sets to limit blast radius
- Set CI job timeouts generously to avoid mid-apply pod crashes
- Consider Terraform Cloud — handles state atomically

> ⚠️ **Never:** Touch state before taking a timestamped backup first

---

# 🔴 Slide 2 · Scenario: State Lock Stuck

**🏗️ Setup**
> *An engineer's laptop died mid-apply. The DynamoDB lock is still held. Nobody on the team can run plan or apply.*

**❓ The Question**
How do you safely resolve a stuck state lock?

**🔍 Diagnosis**
1. Confirm the process is actually dead — check CI for any running job with that lock ID
2. Inspect the DynamoDB lock record: who owns it and when was it created
3. If confirmed dead, force-unlock using the lock ID; then check state for partial writes

**✅ Fix**
```bash
# Step 1: Read the lock record — who owns it?
aws dynamodb get-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "my-bucket/prod/terraform.tfstate"}}'
# ← Shows: Who, Created timestamp, Operation type

# Step 2: After confirming the process is dead
terraform force-unlock abc-123-def  # ← lock ID from error message or DynamoDB

# Step 3: Check for partial state from mid-apply crash
terraform plan  # ← should show zero or only missing imports
```

**🛡️ Prevention**
- Always run Terraform from CI, not developer laptops
- Set CI job timeouts so locks are automatically released on timeout
- Use Terraform Cloud — manages locks centrally with full visibility

> ⚠️ **Never:** Delete the DynamoDB item directly — always use `terraform force-unlock`

---

# 🔴 Slide 3 · Scenario: Resource Exists in Cloud, Not in State

**🏗️ Setup**
> *A junior engineer manually created an RDS instance in the console. The Terraform config already has it defined, but state doesn't know it exists.*

**❓ The Question**
What happens if you just run `terraform apply` and how do you fix it?

**🔍 Diagnosis**
1. `terraform apply` without importing tries to CREATE the RDS instance
2. Fails with "DB identifier already exists" — or creates a duplicate with a random name
3. Fix: import the existing resource into state before applying

**✅ Fix**
```hcl
# Terraform 1.5+: import block (preferred)
import {
  to = aws_db_instance.main
  id = "prod-postgres"  # ← existing RDS identifier in AWS
}
# terraform plan -generate-config-out=generated.tf
```

```bash
# CLI approach (older Terraform versions)
terraform import aws_db_instance.main prod-postgres

# Verify: must show zero destructive changes
terraform plan
```

**🛡️ Prevention**
- Use IAM SCPs to prevent manual console changes in prod
- Run scheduled `terraform plan -refresh-only` in CI to catch manual changes early
- Enforce policy: all infrastructure changes go through Terraform only

> ⚠️ **Never:** Run `terraform apply` after import without carefully reviewing the plan for unexpected diffs

---

# 🔴 Slide 4 · Scenario: Drift Detection in Production

**🏗️ Setup**
> *You suspect someone changed security group rules directly in the AWS console. You need to detect and remediate the drift without causing an outage.*

**❓ The Question**
How do you detect and remediate configuration drift in production?

**🔍 Diagnosis**
1. Run a refresh-only plan to detect drift without applying any changes
2. Determine if the drift is intentional (incident fix) or accidental (unauthorized)
3. Take the appropriate remediation path

**✅ Fix**
```bash
# Step 1: Detect drift — nothing is applied
terraform plan -refresh-only
# Output: ~ aws_security_group.app (changes detected from refresh)
```

```hcl
# Step 2a: Drift is INTENTIONAL — update HCL to match reality, then apply

# Step 2b: Drift is ACCIDENTAL — run terraform apply to restore declared config

# Step 2c: Accept drift long-term (use sparingly)
lifecycle {
  ignore_changes = [ingress]  # ← Terraform ignores this field forever
}
```

**🛡️ Prevention**
- Run `terraform plan -refresh-only` on a nightly schedule in CI
- Enable AWS Config rules to detect out-of-band changes automatically
- Use IAM SCPs to deny direct console changes in prod
- Set up CloudTrail alerts on manual resource modifications

> ⚠️ **Never:** Run `terraform apply` on a drifted state without reviewing the plan — you may destroy intentional incident changes

---

# 🔴 Slide 5 · Scenario: Wrong Workspace Disaster

**🏗️ Setup**
> *An engineer is on the `prod` workspace but runs `terraform destroy` thinking they're in `dev`. Stateful resources are at risk.*

**❓ The Question**
How do you prevent this and recover?

**🔍 Diagnosis**
1. Check if `prevent_destroy` lifecycle was set — if so, the destroy would have errored
2. Check RDS deletion protection — instance may still exist despite destroy running
3. Restore state from S3 versioning, then re-import surviving resources

**✅ Fix**
```hcl
# Prevention: fail loudly if destroying in prod
resource "aws_db_instance" "main" {
  lifecycle {
    prevent_destroy = true  # ← apply/destroy errors before touching the resource
  }
}

# Prevention: require explicit confirmation in prod
variable "confirm_destroy" {
  type    = string
  default = "no"
  validation {
    condition     = var.confirm_destroy == "yes" || terraform.workspace != "prod"
    error_message = "Must set confirm_destroy=yes when destroying in prod"
  }
}
```

```bash
# Recovery: restore state, then re-import surviving resources
terraform import aws_db_instance.main prod-postgres
```

**🛡️ Prevention**
- Set `prevent_destroy = true` on all prod stateful resources (RDS, S3, EKS)
- Enable RDS deletion protection and S3 MFA delete
- Use separate AWS accounts for prod vs dev — cross-account destroy requires role assumption
- Enforce `terraform workspace show` in runbooks before any destroy

> ⚠️ **Never:** Run `terraform destroy` without first running `terraform workspace show`

---

# 🎤 Slide 6 · Follow-up Q&A

---

### Q: What's the difference between `serial` and `lineage` in the state file?
- `serial` is a monotonically increasing integer — every successful apply increments it
- Concurrent applies that finish simultaneously are detected via serial mismatch — Terraform refuses to overwrite
- `lineage` is a UUID assigned at state creation — it never changes
- If two environments accidentally share a state file path, mismatched lineage causes an immediate error, preventing cross-environment corruption

> 💬 **Say:** "Serial is the version counter; lineage is the identity fingerprint — you can't accidentally merge two environments because lineage makes them incompatible."

---

### Q: How do you split a monolithic state file into multiple?
- Pull the monolith: `terraform state pull > monolith.tfstate`
- Use `terraform state mv` with a remote address to move resources into the new state file
- Use `terraform state rm` to remove moved resources from the original state
- Run `terraform plan` in both old and new configs — both must show zero changes

> 💬 **Say:** "state mv is the only safe way to move resources between state files — it updates both states atomically and avoids any destroy/recreate."

> ⚠️ **Never:** Split by deleting from one state and importing in another — this risks destroying real infrastructure during the gap

---
