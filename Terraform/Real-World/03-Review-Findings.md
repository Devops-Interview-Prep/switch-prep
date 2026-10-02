# Review findings: what a tech lead would change

> An honest pull-request review of `devops-platform/`, the way you would deliver it in the interview: prioritised, each finding with the risk, the fix, and the one sentence you would say. Practise by reviewing the code cold first, then compare. Being able to find and *rank* these in eight minutes is the skill Round 1 tests. Paths are relative to `devops-platform/`.

---

## How to deliver a review in an interview

1. Say what is **good** first, in two sentences. It proves you read for intent, not for defects.
2. Give the **three things you would block the PR on** (security, data loss, correctness).
3. Give the **design-level changes** you would schedule, not block on.
4. Give the **nits** in one breath, or skip them.
5. Close with **how your process would have caught them automatically** (checkov, tflint, policy on plan, PR template).

## What is good (say this first)

- Clear three-layer structure: resource modules, composition stacks, thin environment roots; split by rate of change and blast radius.
- Secure defaults where it counts: IMDSv2 required with hop limit 1 on both managed and Karpenter nodes, encrypted gp3 root volumes, EKS Secrets envelope-encrypted with a per-cluster CMK with rotation, all five control-plane log types, private endpoint by default, `authentication_mode = "API"` with `bootstrap_cluster_creator_admin_permissions = false`, namespace-scoped developer access entries.
- Least-privilege controller IAM: the Karpenter policy scopes `TerminateInstances` to tagged instances and `PassRole` to the node role; IRSA trust policies check both `aud` and `sub`.
- Remote state with versioning, encryption, public access block, native S3 locking; one state per stack; cross-stack values through outputs.
- Operational opinions baked into templates: three Karpenter pools with different disruption policies, NodePool `limits` as a runaway guard, DLQ by default on SQS, ECR scan on push and lifecycle rules, subnet tags as controller contracts.
- Dev floats add-on versions, prod pins them. Variable validation on enums (`nat_gateway_mode`, `condition_operator`). Partition-aware ARNs throughout the new modules.

## Blocking findings (would not approve)

| # | Finding | Where | Why it matters | Fix |
|---|---|---|---|---|
| B1 | **A database password was hardcoded in a root module** (removed in this copy; the line is now a comment) | `environments/shared/apps/proda/auth-api-service/dev/main.tf` | Secret in git history, in every clone, in plan output. In a regulated company this is a reportable incident. | Rotate the credential. Use `manage_master_user_password = true` on `aws_db_instance` so RDS writes the secret to Secrets Manager and Terraform never sees it; or at minimum `TF_VAR_` from CI secrets. Add a pre-commit secret scanner (gitleaks) and checkov `CKV_SECRET_*`. Purge history with `git filter-repo`. |
| B2 | **State and plan files were committed** (`terraform.tfstate`, `tfplan`, `destroy.tfplan` under several roots; dropped from this copy) | `environments/*/tfplan`, `environments/shared/dev/_sg-cleanup/terraform.tfstate` | State and plan files contain every sensitive attribute in plaintext, including the password above and RDS endpoints. | `.gitignore` for `*.tfstate*`, `*.tfplan`, `.terraform/`; pre-commit hook; history purge; treat as a credential leak. |
| B3 | **The EFS CSI role is attached the EBS CSI policy** | `stacks/new-environment/03-eks-platform/main.tf`, `module "efs_csi_irsa"` uses `var.ebs_csi_policy_arn` and `AmazonEBSCSIDriverPolicyV2` | EFS driver will fail on first mount with AccessDenied, and the role has unrelated EBS permissions. A copy-paste bug a reviewer must catch. | Use `var.efs_csi_policy_arn` defaulting to `AmazonEFSCSIDriverPolicy`. Add a `terraform test` that asserts the policy ARN per role. |
| B4 | **Provider block inside a reusable stack** | `stacks/application-stack/versions.tf` has `provider "aws" { region = var.aws_region }` | A module with its own provider cannot be used with `count`/`for_each`, cannot be instantiated for a second region, and silently overrides the root's provider config (profile, assume_role, default_tags). | Delete the provider block; keep `required_providers`. Roots own providers. |
| B5 | **Prod EKS API endpoint is public** (restricted to two office IPs) | `environments/example/prod/02-eks-core/terraform.tfvars`: `endpoint_public_access = true` | Office IPs change; a public control-plane endpoint is an audit finding under RBI/SOC 2 regardless of CIDR list. | `endpoint_public_access = false`; reach the API via VPN/VPC or SSM port-forward; CI runs inside the VPC or over PrivateLink. |
| B6 | **RDS defaults allow data loss** | `stacks/application-stack/variables.tf`: `rds_*_skip_final_snapshot = true`, `rds_*_deletion_protection = false`; no `multi_az`; no `prevent_destroy` | A `terraform destroy` or a replace-forcing change deletes the database with no snapshot. | Defaults: `deletion_protection = var.environment == "prod"`, `skip_final_snapshot = false`, `final_snapshot_identifier` set, `multi_az` true in prod, `lifecycle { prevent_destroy = true }` on the instance in the module (toggle via a variable only if you accept the ceremony). Policy on plan: deny `delete` of `aws_db_instance` in prod roots. |

## Design-level findings (schedule, not block)

| # | Finding | Where | Fix |
|---|---|---|---|
| D1 | `count` indexed by position for subnets, route tables, NAT routes; removing the first AZ re-creates everything after it | `modules/network/subnets`, `modules/network/routing` | `for_each` over a map keyed by AZ (`{ "us-east-1a" = "10.150.16.0/20", ... }`). Migrate existing state with `moved` blocks. |
| D2 | Karpenter `EC2NodeClass` uses `alias: al2023@latest` | `modules/eks/karpenter/templates/ec2nodeclasses.yaml.tpl` | Every new AL2023 release drifts every node and Karpenter rolls the fleet unannounced. Pin `al2023@v20250xxx` and bump deliberately through dev then prod. |
| D3 | Karpenter `general-purpose` pool: `WhenEmptyOrUnderutilized` with `consolidateAfter: 30s`, no `budgets`, no schedule | same template | This is the configuration that produced ~800 node replacements a week and user-visible evictions in the churn incident. Raise `consolidateAfter` (minutes to hours), add `budgets` (e.g. `nodes: "10%"` plus an off-hours schedule), and ship PDBs via the shared chart. |
| D4 | NodePool manifests keyed by split index, not by name | `modules/eks/karpenter/main.tf` locals | Re-ordering the template re-creates NodePools. Key the `for_each` map by `yamldecode(doc).metadata.name`. |
| D5 | `terraform_remote_state` couples every downstream root to upstream output *names* and grants read of the whole state (including sensitive outputs) | all roots | Publish the handful of needed values to SSM Parameter Store from the upstream stack and read them with `data "aws_ssm_parameter"`; or scope the remote-state IAM policy. Keeps stacks deploy-order-decoupled and lets non-Terraform consumers (Launchpad, scripts) read the same values. |
| D6 | Environment roots duplicate 100+ variable declarations each (`variables.tf` in every root mirrors the stack) | `environments/*/*/0{1,2,3}-*` | Terragrunt (`terragrunt.hcl` with `inputs`, generated backend) or a tiny root pattern that passes a single `object` variable. Thirty roots times three stacks is already past the point where copy-paste costs more than Terragrunt. |
| D7 | Single NAT gateway in prod | `environments/example/prod/01-network/terraform.tfvars`: `nat_gateway_mode = "single"` | Per-AZ NAT in prod (availability and cross-AZ data cost); the module already supports it. Add `prevent_destroy` on the NAT EIPs because partners allow-list them. |
| D8 | No VPC endpoints | `modules/network/*` | Add gateway endpoints for S3 and DynamoDB and interface endpoints for ECR (`api`, `dkr`), STS, Secrets Manager, KMS, Logs, SSM. Cuts NAT data processing and keeps control traffic private; the 429-from-Maven-via-shared-NAT incident is the story. |
| D9 | KMS key policy is root-only | `modules/security/kms` | Add explicit key-admin and key-user statements, `kms:ViaService` for the consuming service, and alarm on `ScheduleKeyDeletion`. For a fintech, separate keys per data classification. |
| D10 | State bucket uses SSE-S3 (`AES256`), no TLS-only bucket policy, no Object Lock | `bootstrap/main.tf` | SSE-KMS with a dedicated CMK, `aws:SecureTransport` deny policy, Object Lock (governance) on prod state, access logging. State is a secret. |
| D11 | CNI policy on the node role (documented bootstrap compromise) | `modules/iam/eks-roles`, `attach_cni_policy_to_node_role = true` everywhere | Finish the TODO: IRSA or Pod Identity role for `aws-node`, pass it via `service_account_role_arn` on the `vpc-cni` add-on, then flip the flag to false. Until then any pod that escapes to the node has ENI permissions. |
| D12 | Egress `0.0.0.0/0` on every security group, including DB | `modules/security/security-groups`, RDS/ElastiCache modules | Databases do not need egress at all; app and node egress should go through a NAT with allow-listing or Network Firewall in prod. |
| D13 | ECR `image_tag_mutability = "MUTABLE"` | `modules/ecr` | `IMMUTABLE` plus deploy by digest; mutable tags defeat signing and provenance (cosign, SLSA). |
| D14 | `kubectl_manifest` (community provider) on the critical path for Karpenter CRs, ArgoCD repo secret | `modules/eks/karpenter`, roots `03-eks-platform` | Accept for bootstrap, but move NodePools/EC2NodeClasses and the repo secret to an ArgoCD "platform" app once ArgoCD is up, so day-2 changes do not need Terraform and a cluster token. Or use `kubernetes_manifest` with a two-phase apply. |
| D15 | `depends_on` on whole modules (`eks_cluster`, `system_node_group`, `karpenter`, `storage_addons`) | stacks | Module-level `depends_on` makes every value in the module "known after apply" and defers data sources. Prefer implicit dependencies through outputs (pass `module.eks_cluster.cluster_name` rather than `depends_on`). Keep it only where AWS has a real ordering constraint Terraform cannot see (CoreDNS needs nodes). |
| D16 | Access entries with an empty admin list lock you out | `modules/eks/cluster` | `validation` on `cluster_admin_principal_arns` (`length > 0`), or a `precondition` on the cluster resource. |
| D17 | Managed node group: `desired_size` managed, no `ignore_changes`, and `latest_version` on the launch template | `modules/eks/managed-node-group` | Fine for the fixed system pool; document it, and add `lifecycle { ignore_changes = [scaling_config[0].desired_size] }` the day an autoscaler touches the group. |
| D18 | Legacy monolith `modules/eks/main.tf` still present with `arn:aws:` hardcoded and `ReadOnly` ECR policy | `modules/eks/` | Delete or move to `modules/_deprecated/` with a README; dead modules get copied by the next person. |
| D19 | Product-specific `alb` module (three fixed listeners, HTTP only, `target_type = instance`) under a generic name | `modules/alb` | Rename to the product, or generalise (`listeners` map, HTTPS with ACM, `target_type = ip`). For EKS services the LB controller owns ALBs; this module should not be the default path. |
| D20 | S3 module ignores `var.tags`, has no lifecycle rules or TLS-only policy | `modules/s3-bucket` | Apply tags (cost allocation breaks silently without them), add `aws_s3_bucket_policy` denying `aws:SecureTransport = false`, lifecycle rules as variables. |
| D21 | Provider version constraints inconsistent: `~> 5.0` in some modules, `>= 5.0` in others, none in the EKS/IAM modules; roots pin `~> 5.0`; no lock files committed | everywhere | Modules: `>= 5.x` minimums only. Roots: `~> 5.NN` and commit `.terraform.lock.hcl` with multi-platform hashes. Renovate for bumps. |
| D22 | Outputs expose the whole application stack as one `sensitive` object | app roots: `output "stack_outputs" { value = module.app_stack sensitive = true }` | Downstream cannot read the endpoint without `-json`; expose named non-sensitive outputs (endpoint, bucket ARN) and keep only secrets sensitive. |
| D23 | Named AWS profiles in provider blocks (`profile = "example-terraform"`) | app roots, `import-existing`, `bootstrap` | Works on a laptop, not in CI. Roots should rely on ambient credentials (OIDC-assumed role in CI, SSO locally) and optionally `assume_role` blocks; never a hardcoded profile. |
| D24 | `list(any)` for tolerations | `03-eks-platform/variables.tf` | Type it as `list(object({ key = string, operator = string, value = optional(string), effect = string }))` so bad input fails at plan. |
| D25 | No tests, no tflint config, no checkov baseline, no CODEOWNERS, no PR template, no `terraform-docs` | repo | The process half of "IaC standards". See Best-Practices for the pipeline. |

## Nits (one breath)

Missing `description` on several root outputs; `ManagedBy` tag values vary (`terraform`, `devops-launchpad`, `devops-launchpad-bootstrap`); `Environment` tag on Karpenter nodes is set to the client prefix rather than the environment; some files lack trailing newlines; `random_password` with `special = false` is weaker than necessary; `import-existing` root should be archived after adoption; the `bootstrap` default profile and bucket names are company-specific defaults in a module (make them required variables).

## How the pipeline would have caught these

| Finding | Caught by |
|---|---|
| B1 hardcoded password | gitleaks pre-commit; checkov secrets scan; `tfsec` `AWS-0041`-style rules |
| B2 committed state/plan | `.gitignore` plus a CI check that fails on `*.tfstate*`/`*.tfplan` in the tree |
| B3 wrong policy on EFS role | `terraform test` asserting role→policy mapping; a reviewer reading the plan |
| B4 provider in module | tflint `terraform_module_provider_declaration`-style custom rule; module README convention |
| B5 public endpoint in prod | Conftest/OPA on plan JSON: `deny if resource.type == "aws_eks_cluster" and public_access and env == "prod"`; checkov `CKV_AWS_39` |
| B6 RDS deletion defaults | checkov `CKV_AWS_293` (deletion protection), `CKV_AWS_157` (multi-AZ); plan policy denying `delete` on `aws_db_instance` in prod |
| D2/D3 Karpenter template | Kyverno or Conftest on the rendered YAML; a platform review checklist item |
| D13 ECR mutable | checkov `CKV_AWS_51` |
| D21 version pins | tflint `terraform_required_providers`, `terraform_required_version`; Renovate |

## The one-minute version for the interview

"Good structure, good security defaults on the cluster, least-privilege controller IAM. I would block on six things: a password and state files that were committed, the EFS role carrying the EBS policy, a provider block inside a reusable stack, a public prod API endpoint, and RDS defaults that allow data loss. Then I would schedule the `count`-to-`for_each` migration on the network modules, pin the Karpenter AMI alias and soften consolidation, replace `terraform_remote_state` with SSM parameters, and fix the per-root variable duplication with Terragrunt. All of the blockers would have been caught by gitleaks, checkov and a plan policy, which is the pipeline I would put in first."
