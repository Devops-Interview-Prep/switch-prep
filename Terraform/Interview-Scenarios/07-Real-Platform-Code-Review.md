# 🎤 Real Platform Code Review Scenarios
**12 Slides · Scenarios lifted from the real `devops-platform` repo in [../Real-World/](../Real-World/)**

Each slide points at actual code in `Real-World/devops-platform/`. Open the file, find the problem yourself, then read the slide. Answer in the interview shape: root cause → diagnosis → fix → prevention.

---

# 🔴 Slide 1 · Scenario: Password in a Root Module

**🏗️ Setup**
> *A product team opened a PR adding `environments/shared/apps/proda/auth-api-service/dev/main.tf`. Among twenty `rds_mysql_*` arguments is `rds_mysql_password = "Oq…"`. CI is green because there is no secret scanning. The PR has one approval already.*

**❓ The Question**
What do you do in the next hour, the next day, and in the pipeline?

**🔍 Diagnosis**
1. The value is already in Git history on the branch and in every reviewer's clone; treat it as leaked.
2. Check whether it was applied: `terraform state pull | jq '.resources[] | select(.type=="aws_db_instance")'` and CloudTrail `ModifyDBInstance`.
3. Check whether the stack even needed it: `application-stack` already generates one with `random_password` when the variable is empty.

**✅ Fix**
```bash
# Hour 1: rotate, do not debate
aws rds modify-db-instance --db-instance-identifier devops-dev-mysql \
  --manage-master-user-password --apply-immediately     # RDS now owns the secret in Secrets Manager

# Remove from the branch and history
git filter-repo --replace-text <(echo 'Oq…==>REDACTED')  # coordinate: everyone re-clones
```

```hcl
# Day 1: make the module unable to hold a password
resource "aws_db_instance" "this" {
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn
  # password argument removed entirely
}
output "master_user_secret_arn" { value = aws_db_instance.this.master_user_secret[0].secret_arn }
```

**🛡️ Prevention**
- gitleaks in pre-commit and CI; checkov secrets scan; a `tfvars`/root policy that rejects any variable named `*password*` with a literal value
- Modules that cannot accept secrets: no `password` input at all
- Secret values read at runtime by External Secrets Operator from the ARN Terraform outputs

> ⚠️ **Never:** "it is only dev" — dev credentials are reused and dev databases hold copied prod data more often than anyone admits.

---

# 🔴 Slide 2 · Scenario: `terraform.tfstate` and `tfplan` Committed

**🏗️ Setup**
> *`git ls-files | grep -E 'tfstate|tfplan'` in the platform repo returns `environments/example/prod/02-eks-core/tfplan`, `environments/shared/dev/_sg-cleanup/terraform.tfstate` and a `destroy.tfplan`. The repo is private, on Bitbucket, cloned by eleven people.*

**❓ The Question**
How bad is this, and what is the order of operations?

**🔍 Diagnosis**
1. A `tfplan` binary contains the full planned state including sensitive values; a `tfstate` contains every attribute. Equivalent to a credentials leak scoped to what those roots manage (RDS passwords, cluster CA, OIDC URLs, ARNs).
2. `destroy.tfplan` is also an operational hazard: anyone can `terraform apply destroy.tfplan` against the right backend.
3. Enumerate secrets in them: `terraform show -json tfplan | jq '.. | .sensitive_values? // empty'`.

**✅ Fix**
```bash
cat >> .gitignore <<'EOF'
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfplan
tfplan
destroy.tfplan
crash.log
EOF
git rm --cached $(git ls-files | grep -E 'tfstate|tfplan')
git commit -m "Stop tracking state and plan files"
# then history purge + rotate anything those files contained
```

**🛡️ Prevention**
- `.gitignore` committed in the repo root on day one; CI step `! git ls-files | grep -E 'tfstate|tfplan'`
- Plans are CI artifacts with short retention, never files in the working tree
- Pre-commit hook `check-added-large-files` plus a pattern deny

> ⚠️ **Never:** keep a `destroy.tfplan` around "for later". Destroys are planned and applied in the same change window.

---

# 🔴 Slide 3 · Scenario: The EFS Role That Carries the EBS Policy

**🏗️ Setup**
> *First EFS-backed PVC on a new cluster. The pod stays `ContainerCreating` with `AccessDeniedException ... elasticfilesystem:DescribeMountTargets`. The EFS CSI add-on is installed and healthy.*

**❓ The Question**
Root-cause it from the Terraform.

**🔍 Diagnosis**
1. `kubectl describe sa -n kube-system efs-csi-controller-sa` → role ARN `…-efs-csi-driver-role`. Good.
2. `aws iam list-attached-role-policies --role-name clienta-dev-efs-csi-driver-role` → `AmazonEBSCSIDriverPolicyV2`. Wrong policy.
3. In `stacks/new-environment/03-eks-platform/main.tf`, `module "efs_csi_irsa"` sets `managed_policy_arns = [var.ebs_csi_policy_arn != "" ? var.ebs_csi_policy_arn : ".../AmazonEBSCSIDriverPolicyV2"]`. Copy-paste from the EBS block; `var.efs_csi_policy_arn` is declared and never used.

**✅ Fix**
```hcl
module "efs_csi_irsa" {
  source = "../../../modules/iam/irsa-role"
  # ...
  managed_policy_arns = [
    coalesce(var.efs_csi_policy_arn,
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy")
  ]
}
```

```hcl
# tests/csi_roles.tftest.hcl — would have failed on the bug
run "efs_role_gets_efs_policy" {
  command = plan
  assert {
    condition     = contains(module.efs_csi_irsa.managed_policy_arns, "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy")
    error_message = "EFS CSI role must carry the EFS policy"
  }
}
```

**🛡️ Prevention**
- tflint `terraform_unused_declarations` flags the unused `efs_csi_policy_arn` variable
- One `csi_drivers` map with `for_each` instead of two copy-pasted blocks
- Integration smoke test: mount an EFS and an EBS volume after `03` applies

> ⚠️ **Never:** approve two near-identical blocks without diffing them side by side.

---

# 🔴 Slide 4 · Scenario: Provider Block Inside the Application Stack

**🏗️ Setup**
> *A team wants two application stacks in one root for a service that spans `us-east-1` and `ap-south-1`. They write `module "app_us" { providers = { aws = aws.us } }` and `module "app_in" { providers = { aws = aws.in } }`. Plan fails: "Module module.app_us contains provider configuration. Providers cannot be configured within modules using count, for_each or depends_on", and later "provider configuration not present".*

**❓ The Question**
Why, and how do you fix it without breaking the thirty existing roots that call this stack?

**🔍 Diagnosis**
1. `stacks/application-stack/versions.tf` declares `provider "aws" { region = var.aws_region }`. A module with its own provider configuration is a "legacy module"; it cannot be passed providers, counted, or used with `for_each`, and its resources are orphaned if the module block is removed.
2. Existing roots work only because they call the stack exactly once with a matching region.

**✅ Fix**
```hcl
# stacks/application-stack/versions.tf — keep requirements, drop configuration
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws    = { source = "hashicorp/aws", version = ">= 5.0" }
    random = { source = "hashicorp/random", version = ">= 3.5" }
  }
}
# provider "aws" {...}  ← deleted

# every root already has provider "aws" in provider.tf, so plans show no change
# multi-region root:
provider "aws" { alias = "in"  region = "ap-south-1" }
module "app_in" { source = "../../stacks/application-stack"  providers = { aws = aws.in } ... }
```

**🛡️ Prevention**
- Module convention and a tflint custom rule: no `provider` blocks under `modules/` or `stacks/`
- `aws_region` variable removed from the stack (region is a provider property)

> ⚠️ **Never:** remove a legacy module's provider block and its module call in the same apply; the resources need a provider to be destroyed or moved.

---

# 🔴 Slide 5 · Scenario: The 03 Stack Cannot Plan on a Fresh Account

**🏗️ Setup**
> *Launchpad runs all three stacks for a new client. `01` and `02` apply. `03-eks-platform` fails at `plan` with "error reading EKS Cluster: ResourceNotFoundException" even though the cluster exists. Separately, when a cluster was deleted by hand, `terraform destroy` in `03` hangs for 30 minutes.*

**❓ The Question**
Explain both failures from the provider wiring and fix the workflow.

**🔍 Diagnosis**
1. `03/provider.tf` configures `helm` and `kubectl` from `data "aws_eks_cluster"` and `data "aws_eks_cluster_auth"` by `var.cluster_name`. On the first failure the Launchpad passed the cluster *name* from its config before `02`'s output was refreshed (a typo in `cluster_name` between the two tfvars), so the data source looked up a non-existent cluster.
2. On the destroy, the cluster was already gone, so the data source failed or the token was useless; `helm_release` destroy tried to talk to a dead endpoint until timeout. Finalizers on Karpenter CRs and the LB controller's ALBs make this worse.

**✅ Fix**
```hcl
# Take cluster identity from 02's state, not from a second copy in tfvars
data "terraform_remote_state" "eks_core" { ... }
locals { cluster_name = data.terraform_remote_state.eks_core.outputs.cluster_name }
data "aws_eks_cluster" "this" { name = local.cluster_name }
```

```bash
# Destroy order for an environment (reverse of create), scripted in the Launchpad:
terraform -chdir=03-eks-platform destroy   # removes Helm releases, NodePools (nodes drain), ALBs via controller
terraform -chdir=02-eks-core     destroy
terraform -chdir=01-network      destroy
# If the cluster is already gone: terraform state rm the helm/kubectl resources, then destroy the AWS ones
```

**🛡️ Prevention**
- One source of truth for names: outputs, never re-typed
- `precondition` on the data source: cluster status `ACTIVE`
- Documented teardown runbook; `prevent_destroy` on the cluster so "deleted by hand" is hard

> ⚠️ **Never:** put the cluster and the Helm releases that need its token in the same root. This split is the whole reason `03` exists.

---

# 🔴 Slide 6 · Scenario: Remove an AZ, Lose the VPC

**🏗️ Setup**
> *Capacity in `us-east-1a` is constrained. Someone removes the first CIDR from `private_app_subnet_cidrs` in `clienta/dev/01-network/terraform.tfvars`. The plan shows 2 subnets to replace, 2 route tables to replace, 2 NAT routes to replace, and the EKS node group and RDS subnet group to update.*

**❓ The Question**
Why does deleting one subnet replace the others, and how do you fix it safely?

**🔍 Diagnosis**
1. `modules/network/subnets` uses `count = length(var.private_app_subnet_cidrs)` with `cidr_block = var.private_app_subnet_cidrs[count.index]`. Removing index 0 shifts every later element down one; Terraform sees `private_app[0]` changing CIDR and AZ, which forces replacement.
2. Everything that references subnet IDs (route tables, node group, DB subnet groups) cascades.

**✅ Fix**
```hcl
# variables: a map keyed by AZ
variable "private_app_subnets" {
  type = map(string)   # { "us-east-1a" = "10.150.16.0/20", "us-east-1b" = "10.150.32.0/20" }
}
resource "aws_subnet" "private_app" {
  for_each          = var.private_app_subnets
  availability_zone = each.key
  cidr_block        = each.value
}
```

```hcl
# migrate state without replacing anything
moved { from = aws_subnet.private_app[0]  to = aws_subnet.private_app["us-east-1a"] }
moved { from = aws_subnet.private_app[1]  to = aws_subnet.private_app["us-east-1b"] }
moved { from = aws_subnet.private_app[2]  to = aws_subnet.private_app["us-east-1c"] }
# plan must show 0 to add / 0 to destroy before the removal PR
```

**🛡️ Prevention**
- Rule: `count` only for booleans; lists of infrastructure are maps
- Review checklist item: "any `-/+` on a subnet, SG or DB must be explained"
- Plan policy: deny replacement of `aws_subnet` in prod without an override label

> ⚠️ **Never:** apply a plan with replacements on networking in prod because "it's only subnets".

---

# 🔴 Slide 7 · Scenario: Nodes Rotated at 02:00 Without a Deploy

**🏗️ Setup**
> *Pager at 02:10: 40% of a prod cluster's nodes are `NotReady` → gone → replaced within 20 minutes. No Terraform apply, no ArgoCD sync. Karpenter logs show `disrupting via drift`.*

**❓ The Question**
What drifted, and what in the Terraform allowed it?

**🔍 Diagnosis**
1. `modules/eks/karpenter/templates/ec2nodeclasses.yaml.tpl` has `amiSelectorTerms: - alias: al2023@latest`. AWS published a new AL2023 EKS AMI; Karpenter's drift controller marks every node on the old AMI as drifted and replaces them within the disruption budget (there is none set, so default 10%, continuously).
2. The NodePool has no `budgets` with a schedule, so this happens whenever AWS releases, including at night.

**✅ Fix**
```yaml
# EC2NodeClass
amiSelectorTerms:
  - alias: al2023@v20250915      # pinned; bumped by PR through dev → prod
# NodePool
disruption:
  consolidationPolicy: WhenEmptyOrUnderutilized
  consolidateAfter: 1h
  budgets:
    - nodes: "10%"
    - nodes: "0"
      schedule: "0 18 * * *"     # no disruption 18:00–06:00 UTC
      duration: 12h
```

```hcl
variable "karpenter_ami_alias" {
  type = string
  validation {
    condition     = !endswith(var.karpenter_ami_alias, "@latest")
    error_message = "Pin the AMI alias to a version (al2023@vYYYYMMDD); @latest rotates nodes on every AWS release."
  }
}
```

**🛡️ Prevention**
- Renovate-style job that opens a PR when a new AMI alias is published
- PDBs shipped by the shared Helm chart so even allowed rotations are graceful
- Alert on `karpenter_nodeclaims_disrupted_total{reason="drift"}` spikes

> ⚠️ **Never:** `latest` anything in prod: AMI aliases, Helm charts, add-on versions, container tags.

---

# 🔴 Slide 8 · Scenario: NodePools Re-created After a Template Edit

**🏗️ Setup**
> *A platform engineer reorders the NodePool documents in `nodepools.yaml.tpl` to put the infra pool first. Plan: 3 `kubectl_manifest.nodepools` to destroy and 3 to create. Applying would delete the NodePools, Karpenter would terminate every node they own.*

**❓ The Question**
Why does a reorder cause replacement, and how do you make the module safe?

**🔍 Diagnosis**
1. `locals.nodepool_documents = { for index, manifest in compact(split("---", yaml)) : index => ... }` keys the `for_each` by position. Reordering changes which document is at key `0`, so Terraform sees a different `yaml_body` with a different `metadata.name` under the same key, and `kubectl_manifest` replaces on name change.

**✅ Fix**
```hcl
locals {
  nodepool_docs = [for m in compact(split("---", local.nodepools_yaml)) : trimspace(m) if trimspace(m) != ""]
  nodepool_documents = { for d in local.nodepool_docs : yamldecode(d).metadata.name => d }
}
# one-time migration
moved { from = kubectl_manifest.nodepools["0"] to = kubectl_manifest.nodepools["default-on-demand"] }
```

**🛡️ Prevention**
- Keys in `for_each` come from the object's identity, never from its position
- Prefer owning NodePools in an ArgoCD platform app after bootstrap; Argo diffs by name
- `prevent_destroy` on NodePool manifests in prod roots

> ⚠️ **Never:** apply a plan that destroys a NodePool without first annotating its nodes `karpenter.sh/do-not-disrupt` or draining on your schedule.

---

# 🔴 Slide 9 · Scenario: Locked Out of a Brand-New Cluster

**🏗️ Setup**
> *A new client environment. `02-eks-core` applies cleanly. `kubectl get nodes` returns `Unauthorized` for everyone, including the engineer who ran the apply.*

**❓ The Question**
What happened and how do you recover without re-creating the cluster?

**🔍 Diagnosis**
1. `modules/eks/cluster` sets `authentication_mode = "API"` and `bootstrap_cluster_creator_admin_permissions = false` (correct for audit). Access comes only from `aws_eks_access_entry` resources.
2. The tfvars for this client left `cluster_admin_principal_arns = []`. No access entries were created. Nobody is admin.
3. Recovery is possible because access entries are an AWS API, not a Kubernetes object: the AWS identity that can call `eks:CreateAccessEntry` can grant itself access.

**✅ Fix**
```bash
aws eks create-access-entry --cluster-name clienta-dev-eks \
  --principal-arn arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_PlatformAdmin_0123456789abcdef
aws eks associate-access-policy --cluster-name clienta-dev-eks \
  --principal-arn arn:aws:iam::123456789012:role/.../AWSReservedSSO_PlatformAdmin_0123456789abcdef \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster
# then put the ARN in tfvars and `terraform import` the entry so Terraform owns it
```

```hcl
variable "cluster_admin_principal_arns" {
  type = list(string)
  validation {
    condition     = length(var.cluster_admin_principal_arns) > 0
    error_message = "At least one cluster admin principal is required; the creator gets no implicit access."
  }
}
```

**🛡️ Prevention**
- Validation above; a default admin role injected by the stack from a shared variable
- Smoke test after `02`: `aws eks list-access-entries` non-empty and `kubectl auth can-i '*' '*'` for the admin role

> ⚠️ **Never:** flip `bootstrap_cluster_creator_admin_permissions` back to `true` to "fix" this; it recreates the invisible admin auditors flag.

---

# 🔴 Slide 10 · Scenario: Bootstrapping State Without a Chicken-and-Egg

**🏗️ Setup**
> *New AWS account for a regulated client. Policy says: no console-created resources, everything in Terraform, all state remote. The first thing Terraform needs is a state bucket.*

**❓ The Question**
How do you create the backend under those rules, and how does `bootstrap/` in the repo handle it?

**🔍 Diagnosis**
1. The backend cannot create itself. Options: (a) a bootstrap root with local state, then migrate its own state into the bucket it created; (b) create via CLI/console and `import`; (c) an org-level "account factory" that provisions the bucket from a management account.
2. The repo chooses (a) and documents it in the file header; the local `terraform.tfstate` for bootstrap is then the one state file that must be protected by other means (or migrated).

**✅ Fix**
```bash
cd bootstrap && terraform init && terraform apply          # local state
cat > backend.tf <<'EOF'
terraform { backend "s3" {
  bucket = "example-tf-state-123456789012-us-east-1"
  key    = "bootstrap/terraform.tfstate"  region = "us-east-1"
  encrypt = true  use_lockfile = true } }
EOF
terraform init -migrate-state                                # bucket now stores its own state
rm terraform.tfstate*                                        # after verifying `terraform state list`
```

```hcl
# harden the bucket while you are there
resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.tf_state.id
  policy = jsonencode({ Statement = [{ Effect = "Deny", Principal = "*", Action = "s3:*",
    Resource = [aws_s3_bucket.tf_state.arn, "${aws_s3_bucket.tf_state.arn}/*"],
    Condition = { Bool = { "aws:SecureTransport" = "false" } } }] })
}
```

**🛡️ Prevention**
- Account factory (Control Tower / AFT or a Terraform org module) creates the state bucket for every new account from the management account, so `bootstrap/` is only for the very first account
- `prevent_destroy` and Object Lock on the bucket

> ⚠️ **Never:** leave the bootstrap root's local `terraform.tfstate` on a laptop (or in Git, as happened in a sibling root).

---

# 🔴 Slide 11 · Scenario: Orphan Security Groups Blocking a VPC Delete

**🏗️ Setup**
> *A dev VPC destroy fails: `DependencyViolation: resource sg-… has a dependent object`. Four security groups exist that no state file knows about (created by a deleted Helm release of the LB controller and by a manual test).*

**❓ The Question**
Clean them up with an audit trail, using Terraform.

**🔍 Diagnosis**
1. Find them: `aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-… --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]'`, then check `terraform state list` across roots and `driftctl scan` for unmanaged resources.
2. Check dependents: ENIs (`describe-network-interfaces --filters Name=group-id`) and cross-references between SGs.

**✅ Fix**
```hcl
# a throwaway root (the repo's _sg-cleanup pattern), local or remote state
import { to = aws_security_group.orphan["sg-aaa"]  id = "sg-aaa" }
import { to = aws_security_group.orphan["sg-bbb"]  id = "sg-bbb" }
resource "aws_security_group" "orphan" {
  for_each = toset(["sg-aaa", "sg-bbb"])
  lifecycle { prevent_destroy = false }
}
```

```bash
terraform plan -generate-config-out=orphans.tf   # fills in name/vpc so plan is clean
terraform apply                                  # adopt
terraform destroy                                # delete with a plan as the record
```

**🛡️ Prevention**
- LB controller SGs carry `elbv2.k8s.aws/cluster` tags: delete Ingresses before destroying the controller, and run `03` destroy before `01`
- Nightly driftctl/AWS Config "unmanaged resources" report
- Archive the cleanup root after use; do not leave it with local state in the repo

> ⚠️ **Never:** `aws ec2 delete-security-group` in a loop from a laptop in a regulated account without a change record.

---

# 🔴 Slide 12 · Scenario: Prod on a Single NAT Gateway

**🏗️ Setup**
> *`environments/example/prod/01-network/terraform.tfvars` has `nat_gateway_mode = "single"`. An AZ event in `us-east-1a` takes the NAT with it; nodes in `1b` and `1c` are healthy but cannot pull images or reach partner APIs. Partners have allow-listed the one NAT EIP.*

**❓ The Question**
Fix it without changing the egress IP partners know, and without a maintenance window if possible.

**🔍 Diagnosis**
1. `modules/network/routing` supports `per_az`: `nat_gateway_count = length(public_subnet_ids)` and routes pick `aws_nat_gateway.this[count.index % n]`.
2. Switching modes changes `count` from 1 to 3: the existing NAT at index 0 and its EIP are preserved (same index), two new NATs and EIPs are added, and the private route tables for AZ b and c are updated to new NATs. Egress from AZ a keeps the old IP; AZ b and c get new IPs that partners must also allow-list.

**✅ Fix**
```hcl
# tfvars
nat_gateway_mode = "per_az"
```

```hcl
# in the routing module: protect the allow-listed IPs
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"
  lifecycle { prevent_destroy = true }
}
output "nat_public_ips" { value = aws_eip.nat[*].public_ip }   # share with partners before cutover
```

Sequence: plan → confirm `aws_eip.nat[0]` and `aws_nat_gateway.this[0]` are untouched → notify partners of the two new IPs → apply (route updates are atomic per table; brief connection resets on AZ b/c).

**🛡️ Prevention**
- Stack default `per_az` when `environment == "prod"`; plan policy denying `single` in prod
- NAT EIPs documented as external contracts; `prevent_destroy`; alarm on `aws_eip` deletions
- Add VPC endpoints so ECR/S3/STS/Logs do not depend on NAT at all

> ⚠️ **Never:** change NAT topology in prod without first confirming which EIP indexes survive the plan.
