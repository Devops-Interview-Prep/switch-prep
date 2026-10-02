# Rupeek Round 1 — Terraform and Infrastructure as Code

> Module design, state, workspaces vs directories, version discipline, testing, plan/apply gating, drift, secrets, Terraform vs Pulumi vs CDK, and a flawed sample module to practise the live review on.

---

> **Practise on real code:** a sanitised copy of a production platform repo with annotated notes lives in [Terraform/Real-World](../../../Terraform/Real-World/README.md) (layout and flow, block-by-block walkthrough, a full tech-lead review with 30+ findings). Scenario drills built from it are in [Interview-Scenarios 07](../../../Terraform/Interview-Scenarios/07-Real-Platform-Code-Review.md) and [08](../../../Terraform/Interview-Scenarios/08-Design-and-Operations-Drills.md); the standards themselves are in [Best-Practices](../../../Terraform/Best-Practices.md) and the tool-boundary note in [What-To-Use-Terraform-For](../../../Terraform/What-To-Use-Terraform-For.md).

This is the block they open with, and the live module review is where most candidates lose the round. The interviewer wants to see that you have **standards** for modules, state, and review, that you can spot a bad module in two minutes, and that you can explain why Terraform and not something else.

## Module design

**What a module is for.** A module is a unit of reuse **and** a unit of blast radius. Good boundaries follow ownership and lifecycle: things that change together and are owned by the same team belong together; things that change at different rates (a VPC vs an application's SQS queue) do not.

**Three layers that work in practice:**

1. **Resource modules** (building blocks): `vpc`, `eks-cluster`, `rds-postgres`, `s3-bucket`, `irsa-role`. Thin, opinionated wrappers around one or a few resources that bake in the organisation's defaults (encryption on, logging on, tags mandatory, deletion protection on in prod).
2. **Composition modules** (stacks): `eks-platform` composes `eks-cluster` + `karpenter` + `alb-controller` + `external-secrets`. These encode how your platform is assembled.
3. **Root modules** (environments): one directory per environment per account, calling composition modules with environment-specific values. This is where state lives.

**Rules you should be able to state and defend:**

- **Inputs are typed and validated.** Every `variable` has `type`, `description`, and `validation` where it matters (CIDR format, allowed instance families, environment enum). No `type = any` except for pass-through tags.
- **No provider blocks inside reusable modules.** Providers are configured in the root and passed down; a module that declares its own provider cannot be used with `count`/`for_each` and breaks multi-region composition.
- **Outputs expose IDs and ARNs, not whole objects.** Exposing the full resource couples callers to the provider schema.
- **Defaults are the secure choice.** `storage_encrypted = true`, `publicly_accessible = false`, `block_public_acls = true`, `deletion_protection = var.environment == "prod"`. A caller should have to write extra code to be less safe.
- **Modules do not create IAM users, access keys or anything long-lived.** Identity is roles plus IRSA/Pod Identity.
- **One module, one concern.** A module named `app` that creates an RDS instance, a bucket, an IAM role and a Kubernetes namespace is a god-module: its state is a blast radius, its versioning is meaningless, and nobody can reuse half of it.
- **Versioned and pinned.** Modules are consumed by tag (`?ref=v1.4.2`) from a registry or git, never from a branch. Semantic versioning: breaking input changes bump major.
- **Tagging is a module responsibility.** Accept `tags` and merge mandatory tags (`owner`, `cost-center`, `environment`, `service`, `managed-by=terraform`). Use `default_tags` on the AWS provider in root modules so nothing escapes.

**`count` vs `for_each`.** `count` indexes by position; removing the first item re-creates everything after it. `for_each` keys by a stable string, so additions and removals touch only that resource. Rule: `count` only for boolean on/off (`count = var.enabled ? 1 : 0`), `for_each` for collections. Keys must be known at plan time (not computed from another resource's attributes).

**`lifecycle` blocks.** `prevent_destroy` on databases and state buckets; `ignore_changes` for fields managed elsewhere (ASG `desired_capacity` under an autoscaler, an EKS managed node group's `scaling_config.desired_size`, tags added by Kubernetes controllers); `create_before_destroy` for things referenced by others (launch templates, security groups, ACM certs). Be able to say when `ignore_changes` is hiding a design problem (two controllers fighting over the same field).

**`moved` and `import` blocks** (Terraform 1.1+ and 1.5+): refactor module structure without destroying resources; bring console-created resources under management declaratively and in review. Mention these; they show recent hands-on work.

**Terraform data flow pitfalls:** `depends_on` on modules forces the whole module to wait for apply and makes plans show "known after apply" for everything, so prefer implicit dependencies via references. Computed values inside `for_each` keys make the plan fail with "keys must be known". Dynamic blocks are fine; nested dynamic blocks are a smell.

> **Have an opinion:** Flat and boring beats clever. A module should be readable by a mid-level engineer at 2am. If a module needs a README diagram to explain its locals, split it. Reject PRs that introduce a module for a single-use resource; reject PRs that copy-paste a resource block that already exists as a module.

## State management

**What state is.** A JSON mapping from resource addresses to real-world IDs and attributes. It also stores sensitive attributes in plaintext (database passwords, generated secrets), so state is a secret and must be treated like one.

**Remote state done right on AWS:**
- S3 bucket, versioning on, SSE-KMS with a dedicated CMK, bucket policy denying unencrypted puts and non-TLS access, public access blocked, object lock or at least MFA delete considered for prod.
- Locking: DynamoDB table (`LockID` hash key) historically; since Terraform 1.10 the S3 backend supports **native lock files** (`use_lockfile = true`) using conditional writes, which removes the DynamoDB dependency. Know both; say which you use.
- One state file per root module. Never one state for the whole company: plan time, blast radius and lock contention all scale with state size. Rule of thumb: if a plan takes more than a couple of minutes or touches more than a few hundred resources, split.
- Cross-stack references via `terraform_remote_state` data source (read-only, couples to the other stack's output names), or better via SSM Parameter Store / explicit data lookups by tag, which decouples deploy order and lets non-Terraform consumers read the same values.
- State access is IAM-scoped per environment: the dev CI role cannot read prod state. The state bucket is in a separate "shared services" or "tooling" account in a multi-account setup.
- Backups: S3 versioning plus a lifecycle rule; know how to restore a previous version and `terraform state pull/push` in an emergency.

**State surgery you should be able to narrate:** `terraform state mv` (or `moved` blocks) when renaming; `terraform state rm` plus `import` when a resource must be re-adopted; `terraform force-unlock` only after confirming no apply is running (check who holds the lock, when it was taken); `terraform state replace-provider` during provider migrations. Each of these is a change record in a regulated environment.

> **Watch out:** Things that should make you wince during the review: `terraform.tfstate` committed to git; a `backend "local"`; a shared state file across dev and prod; a backend bucket without versioning; a `tfplan` binary committed (it contains secrets); `-auto-approve` in a prod pipeline without a reviewed plan artifact.

## Workspaces vs directories

**Terraform CLI workspaces** give multiple state files for the same configuration, selected by `terraform workspace select`. **Directory-per-environment** gives each environment its own root module and backend configuration.

**The case for directories** (the mainstream answer and the one to defend):
- The backend, provider (account, region, assumed role) and version pins can differ per environment. Workspaces share all of these.
- A `terraform plan` in `envs/prod` cannot accidentally touch dev because the backend key is hard-wired. With workspaces one forgotten `workspace select` applies dev values to prod state.
- Environments can be on different module versions during a rollout (dev on `v2.0.0`, prod still on `v1.9.3`). Workspaces force identical code.
- Access control per directory maps to CI jobs and IAM roles cleanly.
- Code review of "what changes in prod" is a diff in one directory.

**The case for workspaces:** short-lived identical copies (preview environments per PR, one per feature branch) where the config really is identical and the lifecycle is hours or days. Terraform Cloud/Enterprise "workspaces" are a different concept (a unit of state plus run configuration plus variables plus RBAC), and in TFE one workspace per environment per stack **is** the right model.

**Keeping directories DRY:** composition modules carry 95% of the logic; the per-environment root is twenty lines of variables. Tools: Terragrunt (`include`, `dependency`, generated backend blocks, run-all), or plain Terraform with a `shared/` module and symlinked `versions.tf`. Terraform Stacks (HCP Terraform) is the HashiCorp-native answer; mention it as "worth watching, not something I would bet a regulated prod on yet unless already on HCP".

> **Have an opinion:** "Directory per environment, composition modules for DRY, Terragrunt only if the number of stacks times environments gets past about thirty." Then give the example of the HiLabs layout: three ordered stacks (`01-network`, `02-eks-core`, `03-eks-platform`) per account with state in an account-local S3 bucket using native lock files.

## Provider and version discipline

- `required_version` with a pessimistic constraint (`~> 1.9`) in every root module; a module library declares the minimum it needs (`>= 1.5`).
- `required_providers` with `~>` minor pins in roots, `>=` minimums in modules. The `.terraform.lock.hcl` is committed and updated deliberately with `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64` so CI and laptops agree on hashes.
- Provider upgrades are their own PR, run across all environments, with the changelog linked. AWS provider major bumps (4 to 5, 5 to 6) have renamed and removed arguments; the plan must be read for silent re-creations (e.g. S3 bucket sub-resources split in v4).
- Renovate or Dependabot opens the bump PRs; a human reads the plan.
- Pin module sources by tag or commit, never `main`.

## Testing and static analysis

| **Tool** | **What it catches** | **Where it runs / what to say** |
|---|---|---|
| `terraform fmt -check`, `terraform validate` | Formatting, syntax, type errors, unknown arguments | Pre-commit and the first CI stage. Cheap, fail fast. |
| tflint (with `tflint-ruleset-aws`) | Invalid instance types, deprecated syntax, unused declarations, naming conventions, missing `description`, provider-specific mistakes the plan would only surface at apply | CI stage two. Custom rules for your conventions (tag keys, naming). |
| checkov / tfsec (now Trivy) / Terrascan | Security misconfiguration: unencrypted volumes, open security groups, public buckets, missing logging, IAM wildcards | CI with a baseline; `skip` annotations require a justification comment and expire. Output doubles as **audit evidence** for SOC 2 / ISO change-management controls. |
| OPA/Conftest or Sentinel on the plan JSON | Policy as code on the **plan**: "no resource outside ap-south-1", "no `0.0.0.0/0` ingress on port 22", "every RDS has `deletion_protection` in prod", "cost delta above X requires approval" | Plan gating. This is where cost and compliance guardrails go. |
| `terraform test` (1.6+) | Unit tests of module logic using `run` blocks, mock providers (1.7+) so no real resources are created | For module libraries. Replaces much of what terratest did for simple cases. |
| terratest (Go) | Integration tests: apply a module in a sandbox account, assert on real resources (can I reach the endpoint, is encryption on), destroy | Nightly or on module release. Expensive; reserve for core modules (VPC, EKS, RDS). |
| Infracost | Cost delta of the plan posted on the PR | Guardrail: fail or require approval above a threshold. |
| driftctl / scheduled `plan` | Resources changed outside Terraform or not managed at all | Daily job; see drift below. |

> **Have an opinion:** Static checks in pre-commit so humans never see them in CI; checkov with an owned baseline so the signal stays high; `terraform test` with mocks for module logic; terratest only for the three modules whose failure would take the platform down. Policy on plan JSON with Conftest for anything that is really a **business** rule.

## Review process and plan/apply gating

A production-grade pipeline, and the words to use when describing it:

1. **PR opened.** Pre-commit has already run fmt, validate, tflint, checkov, docs generation (`terraform-docs`).
2. **CI runs `plan`** for every affected root module (detect by changed paths), stores the plan file as an artifact, posts a human-readable summary to the PR (Atlantis, Spacelift, env0, Terraform Cloud, or GitHub Actions with `tf-summarize`/Infracost). The plan is run with a **read-only plus plan** role.
3. **Policy evaluation** on the plan JSON (Conftest/OPA or Sentinel): hard failures (public buckets, resources outside the approved region, deletion of a protected resource) block; soft failures (cost delta, new IAM policy) demand a second approver.
4. **Review.** CODEOWNERS routes: platform team for `modules/`, platform plus the owning product team for `envs/<team>/`, security for anything under `iam/` or `kms/`. Reviewers read the **plan**, not only the HCL. Minimum two approvals for prod.
5. **Apply the saved plan artifact**, never a fresh plan, so what was reviewed is what runs. Apply happens from CI with a role that only CI can assume (OIDC federation from the CI provider, no long-lived keys). Dev applies on merge; prod applies behind an environment approval gate with a named approver and a change ticket ID in the commit or PR.
6. **Record.** Plan, policy results, approvals and apply log are retained; this is the SOC 2 / ISO 27001 change-management evidence.
7. **Post-apply**: a drift plan runs within the hour to confirm clean state.

**Atlantis vs Spacelift vs Terraform Cloud vs plain CI:** Atlantis is self-hosted, PR-driven, free, and good enough for a small team; it lacks policy, RBAC and drift out of the box. Spacelift/env0 add policy (OPA), drift detection, stack dependencies and RBAC. HCP Terraform adds Sentinel and private registry. Plain GitHub Actions/GitLab CI works with discipline and a few scripts. Say which you have run and why you would pick one for Rupeek (likely: Atlantis or Spacelift on EKS, OIDC to AWS, OPA policies, because audit wants evidence and RBAC).

**Human factors a tech lead owns:** PR size limits (one stack per PR), a review checklist in the PR template, "plan is attached or it did not happen", no apply from laptops (break-glass role with alerting if used), and a weekly review of `ignore_changes` and `skip` annotations.

## Drift detection

**Where drift comes from:** console changes during incidents, other automation (autoscalers, Kubernetes controllers tagging ENIs and security groups, AWS adding default tags), provider upgrades changing defaults, and resources created outside Terraform entirely.

**Detecting it:**
- Scheduled `terraform plan -detailed-exitcode` per root module (exit 2 means drift) on a cron, posting a summary to a channel and opening a ticket if non-empty. This catches drift in **managed** resources.
- driftctl or AWS Config for **unmanaged** resources (exists in the account, not in any state).
- AWS Config rules and CloudTrail alerts for sensitive changes (security group edits, IAM policy changes) regardless of Terraform.
- Spacelift/env0/HCP drift detection if you are on them.

**Handling it:** the rule is "drift is reconciled in code within one business day": either the manual change is encoded and applied (import or set the value), or Terraform re-applies the desired state. Break-glass console changes during incidents are allowed but must be announced in the incident channel and reconciled in the post-incident action items. For noisy expected drift, fix the root cause (use `ignore_changes` with a comment explaining which controller owns the field) rather than muting the alert.

## Secrets in Terraform

Never put secret values in `.tfvars` committed to git. Generate secrets in Terraform (`random_password`) and write them to Secrets Manager; the value still lands in state, so state encryption and access control carry the weight. Prefer resources that avoid Terraform ever seeing the secret: RDS `manage_master_user_password = true` (RDS writes to Secrets Manager itself), IAM roles not keys, OIDC federation for CI. Mark variables and outputs `sensitive = true` (hides them from CLI output, not from state). Use `ephemeral` resources and write-only arguments (Terraform 1.10/1.11) for the cases where you must pass a secret and do not want it in state; mentioning these shows current knowledge.

## Terraform vs Pulumi vs CDK vs OpenTofu

| **Tool** | **Strengths** | **Weaknesses** |
|---|---|---|
| Terraform | Largest provider ecosystem (AWS, Kubernetes, Helm, Datadog, PagerDuty, Cloudflare), declarative plan diff that auditors and reviewers can read, huge hiring pool, mature tooling (tflint, checkov, Atlantis, Infracost) | HCL is limited for complex logic; BSL licence since 2023 (hence OpenTofu); state is a sharp edge; testing story younger |
| OpenTofu | Drop-in MPL fork; state encryption built in; community governed | Divergence over time; some vendors (Spacelift yes, HCP no) only support one side |
| Pulumi | Real languages (TypeScript, Python, Go) with loops, types, unit tests; good for teams that are developers first; uses Terraform providers under the hood where needed | Imperative-looking code hides what will change; reviewers must trust the preview; smaller community; state service or self-managed backend; harder to keep "boring" |
| AWS CDK / CDKTF | Native AWS constructs, higher-level L2/L3 abstractions; CloudFormation handles state and rollback | AWS only (CDK); CloudFormation limits and slowness; abstraction leaks make debugging hard; CDKTF is Terraform with extra steps |
| CloudFormation / Crossplane | CFN: no state to manage, AWS-native drift detection. Crossplane: Kubernetes-native, GitOps-friendly, control-plane reconciliation | CFN: verbose, slow, poor cross-account story. Crossplane: provider maturity varies, you now run your infra controller on the cluster it creates |

> **Have an opinion:** Terraform (or OpenTofu) for a regulated platform team, because the **plan is the control**: reviewers, auditors and policy engines all read the same diff, and the provider coverage means one tool for AWS, Kubernetes add-ons, Datadog monitors and PagerDuty schedules. Pulumi is the right call when the infra team is mostly application developers and wants to unit-test logic; I would still forbid it for the landing zone. CDK for a single-team AWS-native product, not for a horizontal platform. If asked about the licence: OpenTofu is a credible exit, so the BSL change is not a reason to leave Terraform today, but pin the version and keep modules portable (no HCP-only features).

## The live module review: a method

They will share a module. You have about ten minutes. Narrate this scan order:

1. **Purpose and boundary.** Read the README and `variables.tf` first. What does this module own? Is that one concern? Would I reuse it elsewhere as is?
2. **Interface.** Are variables typed, described and validated? Are there `any` types, secrets as plain variables, or variables that should be fixed defaults? Are outputs minimal and stable?
3. **Versions.** `required_version`, `required_providers` pins, lock file, module `source` refs pinned to tags.
4. **Resources.** `count` where `for_each` belongs; hardcoded regions, account IDs, AZ names, AMI IDs; names that will collide across environments; missing `tags`.
5. **Security defaults.** Encryption, public access, security group rules (`0.0.0.0/0`), IAM policies with `*` actions or resources, IAM users or access keys, missing logging.
6. **Lifecycle and safety.** `prevent_destroy` on stateful things, `create_before_destroy` on referenced things, `ignore_changes` with a reason, `deletion_protection`, `skip_final_snapshot` in prod.
7. **State and operations.** Provider blocks inside the module (bad), `terraform_remote_state` coupling, `local-exec` provisioners (smell), `depends_on` on modules, `null_resource` hacks.
8. **Tests and docs.** Examples directory, `terraform test` or terratest, `terraform-docs` output, CHANGELOG.
9. **How it would be reviewed.** "In my process this PR would fail checkov on X, tflint on Y, and I would ask for Z before approving."

### A flawed sample module to practise on

Read this as if it were the shared screen and find the problems before reading the list below.

```hcl
# modules/app/main.tf
provider "aws" {
  region = "us-east-1"
}

variable "name" {}
variable "db_password" {}
variable "subnets" { type = any }

resource "aws_db_instance" "db" {
  identifier           = "${var.name}-db"
  engine               = "postgres"
  instance_class       = "db.m5.large"
  allocated_storage    = 100
  username             = "admin"
  password             = var.db_password
  publicly_accessible  = true
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db.name
}

resource "aws_db_subnet_group" "db" {
  name       = "${var.name}-db"
  subnet_ids = var.subnets
}

resource "aws_security_group" "db" {
  name   = "${var.name}-db"
  vpc_id = data.aws_vpc.main.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "main" {
  tags = { Name = "main" }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.name}-uploads"
  acl    = "public-read"
}

resource "aws_iam_user" "app" {
  name = "${var.name}-user"
}

resource "aws_iam_user_policy" "app" {
  user   = aws_iam_user.app.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }]
  })
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

output "access_key" { value = aws_iam_access_key.app.id }
output "secret_key" { value = aws_iam_access_key.app.secret }

resource "aws_instance" "worker" {
  count         = 3
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.large"
  subnet_id     = var.subnets[count.index]
  user_data     = file("${path.module}/bootstrap.sh")
}
```

**Findings, in the order you would say them:**

- **Boundary:** database, bucket, IAM identity and EC2 workers in one module called `app`. Four lifecycles, one state blast radius. Split into `rds-postgres`, `s3-bucket`, `irsa-role`/workload identity, and the compute (which should probably not be EC2 at all on an EKS shop).
- **Provider inside the module** with a hardcoded region (and the wrong one for an Indian fintech). Remove; configure in root; pass region as nothing (providers carry it).
- **Untyped, undocumented variables.** `db_password` as a plain variable means it is in tfvars and state; use `manage_master_user_password` so RDS writes the secret to Secrets Manager. `subnets` as `any` should be `list(string)` with validation.
- **RDS:** `publicly_accessible = true`, no `storage_encrypted`, no `kms_key_id`, no `multi_az`, no `backup_retention_period`, no `deletion_protection`, `skip_final_snapshot = true`, `username = "admin"` (reserved in Postgres anyway and a default attackers try), no parameter group, no Performance Insights, no `lifecycle { prevent_destroy }`, instance class hardcoded instead of a variable, no `apply_immediately` consideration, no maintenance window.
- **Security group:** port 5432 from the world. Should be a rule referencing the application security group or the pod CIDR. Also no egress definition and no `aws_vpc_security_group_ingress_rule` (newer resource type with better diffs).
- **Data lookup by tag `Name = "main"`:** fragile coupling; pass `vpc_id` in as a variable.
- **S3:** `acl = "public-read"` (and `acl` on `aws_s3_bucket` is deprecated since provider v4); no `aws_s3_bucket_public_access_block`, no versioning, no SSE-KMS, no bucket policy enforcing TLS, no lifecycle rules, no access logging. Bucket name without account/region suffix will collide across environments.
- **IAM user with an access key and `Action = "*"`.** The single worst thing in the file. Replace with a role assumed via IRSA/Pod Identity (or instance profile if this must be EC2), least-privilege policy scoped to the bucket ARN and the Secrets Manager entry. The secret key is also an **output**, which prints it and stores it in state.
- **EC2 workers:** `count` with `subnet_id = var.subnets[count.index]` means removing a subnet shifts every instance; use `for_each` over a map of AZ to subnet. AMI hardcoded (region-specific, will rot); use an SSM parameter or a data source with an owner filter. `user_data` via `file()` with no `user_data_replace_on_change` so edits do nothing. No `metadata_options { http_tokens = "required" }` (IMDSv2), no root volume encryption, no tags, no instance profile.
- **Globally:** no `tags`/`default_tags`, no `required_version` or `required_providers`, no outputs for things callers actually need (endpoint, bucket ARN), no README, no tests, no examples. Naming uses `var.name` with no environment, so dev and prod resource names collide.
- **Process:** checkov would fail this with roughly fifteen high findings; tflint would flag the deprecated `acl`; a plan policy would reject the public bucket and the IAM wildcard. "This PR would not pass the first CI stage in my pipeline, and I would pair with the author to split it rather than leave twenty comments."

Finish the review with what is **good** if anything is (naming is consistent, a subnet group exists) and with the two or three changes you would ask for first. Reviewers who only list defects read as pedants; tech leads prioritise.

> **Your story:** Tie it to HiLabs: the `devops-platform/terraform` module library (vpc, eks, karpenter, argocd, alb-controller, IRSA, rds, elasticache, sqs, ecr, route53, kms), the three ordered stacks per account, S3 state with native lock files, and the known debt you can be honest about (a committed `terraform.tfstate` in one repo, `tfplan` binaries in another) along with the fix (pre-commit hook plus `.gitignore` plus history rewrite plus credential rotation). Honesty about debt you have **found and fixed** scores higher than claiming perfection.

## Interview questions and model answers

### Q1: How do you decide module boundaries?

By ownership and lifecycle: things that change together, are owned by one team and share a blast radius go together. Three layers: resource modules with secure defaults, composition modules that assemble the platform, root modules per environment that hold state. The test is "can a mid-level engineer reuse this without reading its internals, and does destroying it only affect what its name says". A module that creates a database and an IAM user is two modules.

---

### Q2: Workspaces or directories, and why?

Directories per environment, composition modules for reuse. Workspaces share backend, provider config and code version, so one forgotten `workspace select` can apply dev values to prod, and you cannot roll a module upgrade through dev first. Workspaces are fine for ephemeral identical copies such as PR preview environments. If the matrix of stacks times environments grows large, Terragrunt or HCP workspaces keep it DRY.

---

### Q3: Walk me through your state setup.

One state per root module in an S3 bucket in the tooling account: versioning, SSE-KMS with a dedicated key, TLS-only bucket policy, public access block, native lock files (Terraform 1.10+) or a DynamoDB lock table on older versions. IAM scoped so the dev CI role cannot read prod state. Cross-stack values via SSM parameters rather than `terraform_remote_state` so stacks are not deploy-order coupled. State restore is an S3 version rollback, and we have practised it.

---

### Q4: Someone changed a security group in the console during an incident. What happens next?

Allowed as break-glass, announced in the incident channel. The nightly drift plan (or the post-incident one) shows the diff. Within one business day the change is either encoded in Terraform and applied, or reverted by apply. CloudTrail alert on `AuthorizeSecurityGroupIngress` outside CI roles tells us the same day even if nobody announced it. Recurrent drift on the same field means a design problem, not a discipline problem.

---

### Q5: How do you gate prod applies?

PR with plan artifact posted, policy checks on plan JSON, two approvals including CODEOWNERS for IAM/KMS paths, change ticket ID referenced, apply of the **saved plan** from CI using an OIDC-federated role with no long-lived keys, environment approval in the pipeline with a named approver, logs and plan retained as audit evidence. Nobody applies from a laptop; the break-glass role pages when assumed.

---

### Q6: What do tflint, checkov and terratest each give you?

tflint: provider-aware lint (invalid instance types, deprecated arguments, naming) that `validate` misses. checkov (or Trivy/tfsec): security and compliance misconfiguration against CIS-style rules, with a managed baseline; the output is also audit evidence. terratest: Go integration tests that apply a module in a sandbox and assert on real behaviour; expensive, so reserved for core modules. `terraform test` with mock providers now covers most unit-level module logic cheaply.

---

### Q7: How do you handle provider upgrades across thirty root modules?

Renovate opens the bump; CI plans every root module and posts summaries; a human reads for re-creates and changed defaults; roll through dev, staging, prod on separate days; lock file regenerated for all platforms. Major versions get a dedicated branch and a written migration note. Modules declare minimums, roots pin minors.

---

### Q8: Why not Pulumi?

Pulumi is better when the team wants real language features and unit tests, and I would choose it for a developer-led team building app infra. For a horizontal platform in a regulated company the reviewable declarative plan is the control auditors and reviewers rely on; HCL's limits are a feature there. Also hiring pool and tooling depth. I keep Pulumi as the answer for the day the team is mostly SDEs.

---

### Q9: What is in your PR template for Terraform?

Which root modules are affected and link to each plan; risk (re-create, downtime, data); rollback plan; change ticket; checkov/tflint status; cost delta from Infracost; whether a manual step precedes or follows apply; reviewers from CODEOWNERS. Plus a line: "I have read the plan output, not only the HCL."

---

### Q10: How do you keep secrets out of Terraform?

Prefer designs where Terraform never sees the value: RDS-managed master password, IAM roles instead of keys, OIDC for CI, External Secrets Operator pulling from Secrets Manager at runtime. Where Terraform must generate a secret, write it to Secrets Manager, mark it sensitive, rely on state encryption and tight state IAM, and use ephemeral resources or write-only arguments on recent Terraform so the value is not persisted.

---

### Q11: How would you bring a hand-built environment under Terraform?

Inventory with driftctl or AWS Config; write modules that match reality first (no behavioural change), use `import` blocks in a PR so adoption is reviewed, plan until it shows zero changes, then start converging to standards in follow-up PRs with explicit plans. Tag everything with `managed-by` as you go. Never import and change in the same apply.

---

### Q12: A plan shows an RDS instance will be replaced. What do you do?

Stop and find the cause: changed identifier, engine major version, subnet group, encryption toggles, or a provider default change. Options: `ignore_changes` if it is a controller-managed field, `moved` if it is a rename, blue/green deployment or snapshot/restore if the change is real. Never apply a replace on a stateful resource without a maintenance window, a snapshot, and `prevent_destroy` removed deliberately in a separate commit.

---
