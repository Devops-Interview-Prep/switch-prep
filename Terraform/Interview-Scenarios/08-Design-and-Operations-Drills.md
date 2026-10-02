# 🎤 Design and Operations Drills
**14 Slides · Migrations, upgrades, policy, DR, multi-account, live-coding prompts**

Tech-lead-level scenarios that go beyond a single module: you are asked to *design the change*, *sequence it*, and *prove it is safe*. Use the real repo in [../Real-World/](../Real-World/) as the estate you are changing.

---

# 🔴 Slide 1 · Scenario: Thirty Roots, One Variable Change

**🏗️ Setup**
> *Security wants `enabled_cluster_log_types` to include all five log types everywhere and `endpoint_public_access = false` in every prod root. There are 30 environment roots, each with its own copy of `variables.tf` and `terraform.tfvars` mirroring the stack.*

**❓ The Question**
Design the repo change so that this takes one PR now and future policy changes take one line.

**🔍 Diagnosis**
1. The duplication is structural: each root re-declares 40 to 100 variables to pass them through to the stack. Any policy default must be changed in every tfvars.
2. Two viable fixes: Terragrunt with a shared `terragrunt.hcl` and per-env `inputs`, or plain Terraform roots that pass one typed `object` with `optional()` attributes so defaults live in the stack.

**✅ Fix**
```hcl
# Option A: Terragrunt
# environments/terragrunt.hcl (root)
remote_state { backend = "s3"  config = { bucket = "example-tf-state-${get_aws_account_id()}-us-east-1"
  key = "launchpad/${path_relative_to_include()}/terraform.tfstate"  encrypt = true  use_lockfile = true } }
generate "provider" { path = "provider.tf"  if_exists = "overwrite"  contents = <<EOF
provider "aws" { region = "us-east-1"  default_tags { tags = { ManagedBy = "terraform" } } }
EOF }
inputs = { enabled_cluster_log_types = ["api","audit","authenticator","controllerManager","scheduler"] }

# environments/example/prod/02-eks-core/terragrunt.hcl
include "root" { path = find_in_parent_folders() }
terraform { source = "../../../../stacks/new-environment//02-eks-core" }
dependency "network" { config_path = "../01-network" }
inputs = { client = "example"  environment = "prod"  endpoint_public_access = false
           cluster_subnet_ids = dependency.network.outputs.eks_subnet_ids }
```

```hcl
# Option B: one object variable in the stack with policy defaults
variable "cluster" {
  type = object({
    version                = string
    endpoint_public_access = optional(bool, false)
    log_types              = optional(list(string), ["api","audit","authenticator","controllerManager","scheduler"])
  })
}
```

**🛡️ Prevention**
- Policy defaults live in exactly one place (the stack or the root `terragrunt.hcl`); roots carry only what differs
- Plan policy enforces the security values regardless of where they are set

> ⚠️ **Never:** fix the thirty files with `sed` and call it done; the next policy change repeats the pain.

---

# 🔴 Slide 2 · Scenario: Split a Monolithic State

**🏗️ Setup**
> *An older client environment used the legacy `modules/eks/main.tf` monolith in one root with the VPC: 400 resources, 9-minute plans, every add-on bump risks the VPC. Move it to the 01/02/03 layout with zero downtime.*

**❓ The Question**
Sequence the migration.

**🔍 Diagnosis**
1. Nothing may be destroyed: this is pure state movement plus code reshaping.
2. Tools: `terraform state mv` with `-state-out` to a new backend, or (cleaner) `moved` blocks cannot cross state files, so use `state mv` between backends, or `import` blocks into the new roots plus `state rm` from the old.

**✅ Fix**
```bash
# 1. Freeze: lock the old root (CI disabled, announce)
# 2. Create new roots with backends; terraform init each
# 3. For each resource, import into the new root (Terraform 1.5+ import blocks, reviewable)
cat > environments/legacy/dev/01-network/import.tf <<'EOF'
import { to = module.network.module.vpc.aws_vpc.this  id = "vpc-0123…" }
import { to = module.network.module.subnets.aws_subnet.private_app["us-east-1a"]  id = "subnet-0123…" }
EOF
terraform plan -generate-config-out=/dev/null      # must show 0 add / 0 change / 0 destroy after config tuning
terraform apply                                    # writes state only
# 4. Remove from old state (not from AWS)
terraform -chdir=legacy-root state rm module.eks.aws_vpc.this ...
# 5. Old root plan must be empty; archive it
```

**🛡️ Prevention**
- Start new environments on the split layout (already the default)
- Keep per-root resource counts under a few hundred; alert on plan duration

> ⚠️ **Never:** run `terraform destroy` on the old root "because everything is imported now" without a diff of `state list` on both sides.

---

# 🔴 Slide 3 · Scenario: IRSA to Pod Identity

**🏗️ Setup**
> *New clusters should use EKS Pod Identity for application roles. The repo's `modules/iam/irsa-role` is used by CSI drivers, Karpenter and dozens of app roles.*

**❓ The Question**
Design the module change and the rollout.

**🔍 Diagnosis**
1. Pod Identity needs the `eks-pod-identity-agent` add-on (already in the add-on map), a role trusting `pods.eks.amazonaws.com`, and an `aws_eks_pod_identity_association`. No OIDC provider per cluster, no SA annotation.
2. Some add-ons still require IRSA (check the matrix); keep both paths.

**✅ Fix**
```hcl
# modules/iam/workload-role (new): one module, two trust modes
variable "identity_mode" { type = string  default = "pod-identity"
  validation { condition = contains(["irsa","pod-identity"], var.identity_mode) error_message = "irsa or pod-identity" } }

resource "aws_iam_role" "this" {
  assume_role_policy = var.identity_mode == "pod-identity" ? jsonencode({ Statement = [{
      Effect = "Allow", Principal = { Service = "pods.eks.amazonaws.com" },
      Action = ["sts:AssumeRole", "sts:TagSession"] }] }) : local.irsa_trust
}
resource "aws_eks_pod_identity_association" "this" {
  for_each        = var.identity_mode == "pod-identity" ? var.service_accounts : {}
  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.name
  role_arn        = aws_iam_role.this.arn
}
```

Rollout: new clusters default `pod-identity`; existing roles migrate per service by adding the association first, removing the SA annotation second, switching the trust policy third (a role can trust both during the change).

**🛡️ Prevention**
- `moved` from `irsa-role` to the new module so no role is re-created
- A test asserting trust policy per mode

> ⚠️ **Never:** switch the trust policy before the association exists; the pod loses credentials immediately.

---

# 🔴 Slide 4 · Scenario: AWS Provider Major Upgrade Across the Estate

**🏗️ Setup**
> *Renovate opens "Update hashicorp/aws to v6". Thirty roots. The changelog lists removed arguments on S3 and changes in default tags behaviour.*

**❓ The Question**
Run the upgrade without surprises.

**🔍 Diagnosis**
1. Modules declare `>= 5.0` so they will accept v6; roots pin `~> 5.0` so nothing changes until a root is bumped. Good separation.
2. Risk is silent replacements and changed defaults, visible only in plans.

**✅ Fix**
```bash
# 1. Branch: bump one dev root; terraform init -upgrade; providers lock for all platforms
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64
# 2. Plan every root in CI matrix; fail the job on any -/+ (replacement)
terraform show -json plan.out | jq -e '[.resource_changes[] | select(.change.actions|index("delete"))] | length == 0'
# 3. Fix modules for removed arguments behind version guards if both majors must coexist
# 4. Roll: dev roots → staging → prod, one PR per tier, lock file committed each time
```

**🛡️ Prevention**
- Renovate grouped PR per tier with the plan summary attached
- Module library tested with `terraform test` against both provider majors during the overlap

> ⚠️ **Never:** `terraform init -upgrade` in a prod root on a laptop to "see what happens".

---

# 🔴 Slide 5 · Scenario: Console Change During an Incident

**🏗️ Setup**
> *During a partner outage an engineer adds an inbound rule to the RDS security group from the console to let a bastion run diagnostics. Incident closes at 03:00. Nobody touches Terraform.*

**❓ The Question**
What detects this, when, and what is the correct reconciliation?

**🔍 Diagnosis**
1. Nightly drift job: `terraform plan -detailed-exitcode` in `environments/shared/apps/.../dev` exits 2 and shows the rule as a change to revoke (inline `ingress` on the RDS module's SG means the module *will* remove it on next apply).
2. Also detectable same-hour via CloudTrail `AuthorizeSecurityGroupIngress` by a non-CI principal → EventBridge → alert.

**✅ Fix**
```bash
# Decision within one business day:
# (a) the rule was temporary → apply to revert (announce first), or
# (b) it should stay → encode it
```

```hcl
# encode as a standalone rule so the module's inline rules stop fighting it
resource "aws_vpc_security_group_ingress_rule" "bastion_pg" {
  security_group_id            = module.app_stack.rds_postgres_security_group_id
  referenced_security_group_id = var.bastion_sg_id
  from_port = 5432  to_port = 5432  ip_protocol = "tcp"
  description = "Bastion diagnostics (INC-1234)"
}
```

**🛡️ Prevention**
- Break-glass policy: console changes allowed, must be posted in the incident channel, reconciled in the post-incident actions
- Convert modules from inline `ingress {}` blocks to standalone rule resources so adoption is possible without a replace
- Session Manager through a bastion-less path removes most reasons for ad hoc SG rules

> ⚠️ **Never:** suppress the drift alert for that root "until the review"; muted drift is how unmanaged infrastructure is born.

---

# 🔴 Slide 6 · Scenario: Policy on the Plan

**🏗️ Setup**
> *You own IaC standards. Write the first five policies that run on every plan and block merges.*

**❓ The Question**
Which five, and show one in Rego.

**🔍 Diagnosis**
Pick policies that encode the blockers from the real review: region allow-list, no public EKS endpoint in prod, no deletion of stateful resources without an override, mandatory tags, no IAM wildcard on write actions.

**✅ Fix**
```rego
# policy/terraform/eks_public_endpoint.rego  (Conftest on `terraform show -json plan.out`)
package main

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_eks_cluster"
  after := rc.change.after
  after.vpc_config[0].endpoint_public_access == true
  contains(rc.address, "prod")           # or read an env tag
  msg := sprintf("%s: public EKS endpoint is not allowed in prod", [rc.address])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_db_instance"
  rc.change.actions[_] == "delete"
  not input.variables.allow_db_delete.value
  msg := sprintf("%s: deleting a database requires allow_db_delete=true and a change ticket", [rc.address])
}
```

```yaml
# CI step
- run: terraform show -json plan.out > plan.json
- run: conftest test plan.json -p policy/terraform --fail-on-warn
```

**🛡️ Prevention**
- Policies versioned with tests (`conftest verify`); exceptions as labelled variables with expiry
- Infracost as a sixth policy: cost delta above a threshold needs a second approver

> ⚠️ **Never:** put business rules only in a human checklist; humans skim at 17:55 on a Friday.

---

# 🔴 Slide 7 · Scenario: Blue/Green Cluster Upgrade Through Terraform

**🏗️ Setup**
> *A prod cluster is three minors behind and still uses the legacy monolith module. In-place upgrade is judged too risky. Design a blue/green with the 01/02/03 layout.*

**❓ The Question**
What is shared, what is new, how does traffic move, how do you roll back?

**🔍 Diagnosis**
1. Shared: `01-network` (same VPC, subnets, NAT, EIPs) and the application stacks (RDS, S3, SQS live outside the cluster).
2. New: a second `02-eks-core` and `03-eks-platform` root pair (`example/prod-green/`) with the new version, same subnets (the subnet tags `karpenter.sh/discovery` are per cluster name, so add the green cluster's tag).
3. Traffic: ArgoCD on green syncs the same Helm-values repos; the shared internal ALB's target groups switch via Ingress `group.name` ownership, or Route 53 weighted records between two ALBs.

**✅ Fix**
```hcl
# environments/example/prod-green/02-eks-core/terraform.tfvars
cluster_name    = "example-prod-green-eks"
cluster_version = "1.36"
# 01-network: add discovery tag for the second cluster
private_app_subnet_tags = {
  "kubernetes.io/role/internal-elb"            = "1"
  "karpenter.sh/discovery/example-prod-eks"     = "owned"   # or keep one tag per cluster via selector terms
}
```

Cutover: green up → platform add-ons healthy → ArgoCD syncs apps → smoke tests → Route 53 weights 10/90 → 50/50 → 100 → blue scaled to zero → blue destroyed after a week. Rollback is the weights.

**🛡️ Prevention**
- Keep clusters within one minor of current so blue/green is the exception
- Application stacks never inside cluster roots (already true), which is what makes this possible

> ⚠️ **Never:** share the Karpenter node IAM role's single access entry across two clusters without checking; access entries are per cluster.

---

# 🔴 Slide 8 · Scenario: The State Bucket Was Deleted

**🏗️ Setup**
> *A cleanup script in the tooling account deleted the state bucket. Versioning was on, but the bucket is gone. 60 state files.*

**❓ The Question**
Recover, and make it impossible to repeat.

**🔍 Diagnosis**
1. If S3 replication to a second bucket existed, restore from the replica. If not: CI artifacts of recent plans (`terraform show -json`), the Launchpad's logs, and the last `terraform state pull` on engineers' machines are partial sources.
2. Worst case: re-import every resource with `import` blocks generated from tags (`ManagedBy`, `Stack`) using `terraform plan -generate-config-out`.

**✅ Fix**
```hcl
# bootstrap: make the bucket un-deletable and replicated
resource "aws_s3_bucket" "tf_state" { bucket = var.state_bucket_name  force_destroy = false
  lifecycle { prevent_destroy = true } }
resource "aws_s3_bucket_object_lock_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule { default_retention { mode = "GOVERNANCE"  days = 30 } }
}
resource "aws_s3_bucket_replication_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id  role = aws_iam_role.replication.arn
  rule { id = "dr"  status = "Enabled"  destination { bucket = aws_s3_bucket.tf_state_dr.arn } }
}
```

```json
// SCP in the tooling OU
{ "Effect": "Deny", "Action": ["s3:DeleteBucket"], "Resource": "arn:aws:s3:::example-tf-state-*" }
```

**🛡️ Prevention**
- Object Lock + replication + SCP deny on delete + CloudTrail alarm on `DeleteBucket`
- Quarterly restore drill of one state file from the replica

> ⚠️ **Never:** rely on versioning alone; versioning does not survive bucket deletion.

---

# 🔴 Slide 9 · Scenario: Multi-Account Roots with One CI Role

**🏗️ Setup**
> *Rupeek-style setup: separate accounts for RFPL prod, RCPL prod, non-prod, tooling. CI runs in tooling. Roots must apply into the right account with no static keys.*

**❓ The Question**
Design provider and IAM wiring.

**✅ Fix**
```hcl
# roots: ambient CI credentials (OIDC from the CI provider) + assume_role into the target account
provider "aws" {
  region = "ap-south-1"
  assume_role {
    role_arn     = "arn:aws:iam::${var.target_account_id}:role/terraform-apply"
    session_name = "ci-${var.pipeline_id}"
    external_id  = var.external_id
  }
  default_tags { tags = { ManagedBy = "terraform", Stack = var.stack_name, Environment = var.environment } }
}
```

```hcl
# target account: two roles, plan vs apply
resource "aws_iam_role" "terraform_plan"  { ... }   # ReadOnlyAccess + s3/dynamodb on the state prefix
resource "aws_iam_role" "terraform_apply" { ... }   # scoped admin with a permission boundary, trust = tooling CI role only,
                                                     # condition on aws:PrincipalTag/pipeline = "prod-apply"
```

**🛡️ Prevention**
- State bucket in tooling with per-prefix IAM (`launchpad/environments/example/prod/*` readable only by prod roles)
- Permission boundary on `terraform_apply` so it cannot create roles beyond itself
- CloudTrail alarm on `AssumeRole` of `terraform-apply` from anything but the CI role

> ⚠️ **Never:** `profile = "..."` in a provider block in a root that CI runs; it ties the root to someone's laptop.

---

# 🔴 Slide 10 · Scenario: Rotate the RDS Master Password Without Downtime

**🏗️ Setup**
> *The hardcoded password incident. Twenty RDS instances created by `application-stack` with `random_password` in state. Move all of them to RDS-managed secrets with rotation, zero app downtime.*

**✅ Fix**
```hcl
# module: switch, keep both attributes during migration
resource "aws_db_instance" "this" {
  manage_master_user_password = var.manage_master_user_password
  password                    = var.manage_master_user_password ? null : var.password
  lifecycle { ignore_changes = [password] }   # remove after migration
}
```

Sequence per instance: apply with `manage_master_user_password = true` (RDS generates a new secret, old password invalid shortly after) → apps must already read credentials via ESO from the RDS-managed secret ARN, so first point ESO at the new secret, then flip. Rotation schedule on the secret; apps re-read on rotation (connection pool refresh or sidecar).

**🛡️ Prevention**
- Remove `random_password` from the stack; delete the `rds_*_password` variables entirely
- Pre-commit `gitleaks`; checkov secret rules

> ⚠️ **Never:** flip `manage_master_user_password` while apps still have the old password baked into a Kubernetes Secret with no reload.

---

# 🔴 Slide 11 · Scenario: Add a DR Region

**🏗️ Setup**
> *Regulator asks for a tested DR in Hyderabad for the lending core. Current estate is Mumbai only, built with the 01/02/03 layout.*

**✅ Fix**
- `environments/example/prod-dr/{01,02,03}` with `aws_region = "ap-south-2"`, same stacks, smaller `node_desired_size`, `karpenter_replicas = 1` (pilot light).
- Data: Aurora Global Database (secondary cluster resource in the DR root), S3 CRR from the application-stack buckets to DR buckets (add `replication` to `modules/s3-bucket`), ECR replication rules so images exist in both regions, Secrets Manager multi-region replicas, KMS multi-region keys.
- Routing: Route 53 health-checked failover records in a shared DNS root.
- The provider block per region lives in the root; stacks stay region-agnostic (another reason to delete the provider from `application-stack`).

**🛡️ Prevention**
- A DR drill runbook as code: promote Aurora secondary, scale Karpenter pools, flip DNS; executed twice a year with timings as audit evidence
- Service availability check for `ap-south-2` before promising every component

> ⚠️ **Never:** build DR by copying tfvars without making the stacks region-agnostic first; the second region will drift from the first within a month.

---

# 🔴 Slide 12 · Live-Coding Prompt: Write an S3 Bucket Module in 15 Minutes

**🏗️ Setup**
> *"Write a production-grade S3 bucket module. Talk while you type."*

**✅ Checklist to hit (in order of speaking)**
1. `variables.tf`: `name` (validated lowercase/dns), `kms_key_arn` (optional, default AWS-managed), `versioning` (bool, default true), `lifecycle_rules` (list of objects with `optional()`), `force_destroy` (default false), `tags`.
2. `main.tf`: bucket; versioning; SSE-KMS with `bucket_key_enabled`; public access block (all four true); ownership controls `BucketOwnerEnforced`; TLS-only bucket policy; lifecycle configuration from the variable (`dynamic "rule"`); optional logging; `prevent_destroy` behind a variable only if asked.
3. `outputs.tf`: `id`, `arn`, `regional_domain_name`.
4. `versions.tf`: `required_version`, `required_providers aws >= 5.0`, no provider block.
5. Say what you would add with more time: replication, Object Lock, access points, a `terraform test`.

```hcl
resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.tls_only.json
}
data "aws_iam_policy_document" "tls_only" {
  statement {
    effect = "Deny"  actions = ["s3:*"]  resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
    principals { type = "*"  identifiers = ["*"] }
    condition { test = "Bool"  variable = "aws:SecureTransport"  values = ["false"] }
  }
}
```

> ⚠️ **Never:** reach for `acl = "private"`; use ownership controls and public access block.

---

# 🔴 Slide 13 · Live-Coding Prompt: Fix This Plan Output

**🏗️ Setup**
> *You are shown a plan: `module.network.aws_subnet.private_app[0] must be replaced` with `cidr_block: "10.150.16.0/20" -> "10.150.32.0/20"  # forces replacement`, plus cascading node group and DB subnet group updates.*

**✅ Answer shape**
1. Read it aloud: positional `count` with a list element removed (Slide 6 of 07).
2. Do not apply. Add `moved` blocks (or `terraform state mv`) to realign indexes, or convert to `for_each` with `moved`, re-plan to zero destroys.
3. If the removal is intentional, drain the node group from that AZ first, then remove in a separate change.

> ⚠️ **Never:** explain a replacement away as "Terraform being Terraform".

---

# 🔴 Slide 14 · Live-Coding Prompt: Module Versioning and Release

**🏗️ Setup**
> *"Your modules live in a monorepo today. Two more repos want to use them. Design versioning and release."*

**✅ Answer shape**
- Move `modules/` to a `terraform-modules` repo (or keep monorepo with tags per module path), semantic version tags per module (`eks-cluster/v1.4.2`), CHANGELOG, `terraform-docs` generated README, `terraform test` in CI, release on tag.
- Consumers pin: `source = "git::ssh://git@github.com/example-org/terraform-modules.git//eks/cluster?ref=eks-cluster/v1.4.2"` or a private registry (HCP, Spacelift, GitLab).
- Renovate bumps consumers; breaking changes bump major and ship a `moved`-block migration guide.
- Deprecation policy: two minors overlap, deleted after.

> ⚠️ **Never:** `ref=main`.
