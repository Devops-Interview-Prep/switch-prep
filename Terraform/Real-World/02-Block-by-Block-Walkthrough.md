# Block-by-block walkthrough

> Each stack and module in `devops-platform/`, block by block: what the resource does, why it is written the way it is, and the failure it protects against. Interviewers who hand you a module want to hear exactly this kind of narration. Paths are relative to `devops-platform/`.

---

## bootstrap/

```hcl
resource "aws_s3_bucket" "tf_state" { bucket = var.state_bucket_name  force_destroy = false }
resource "aws_s3_bucket_versioning" "tf_state" { versioning_configuration { status = "Enabled" } }
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" { ... sse_algorithm = "AES256" }
resource "aws_s3_bucket_public_access_block" "tf_state" { block_public_acls = true ... }
resource "aws_s3_bucket_lifecycle_configuration" "tf_state" { noncurrent_version_expiration { noncurrent_days = 90 } }
resource "aws_dynamodb_table" "tf_lock" { billing_mode = "PAY_PER_REQUEST"  hash_key = "LockID" }
```

- **Separate sub-resources for versioning, encryption, public-access block.** AWS provider v4 split these out of `aws_s3_bucket`; writing them as separate resources is the current idiom and avoids the deprecated inline `acl`/`versioning` arguments.
- **`force_destroy = false`.** A `terraform destroy` on this root must not be able to delete state history.
- **Versioning + 90-day noncurrent expiry.** Versioning is the state backup; the lifecycle rule bounds the cost. Restoring state is "download previous version, `terraform state push`".
- **`LockID` hash key.** The exact schema the S3 backend expects for DynamoDB locking. With Terraform 1.10+ `use_lockfile = true` the table becomes optional; the repo keeps both during migration.
- **Local state, on purpose.** The header comment says so. The alternative is to create the bucket by hand or with the CLI and import it; both are fine as long as it is documented.
- **What is missing (see findings):** SSE-KMS with a CMK instead of AES256, a bucket policy denying non-TLS access, and Object Lock for prod state.

## stacks/new-environment/01-network/ and modules/network/*

### locals and tags

```hcl
locals {
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : "${var.client}-${var.environment}"
  common_tags = merge(var.tags, { Client = var.client, Environment = var.environment, ManagedBy = "devops-launchpad", Stack = "01-network" })
}
```

Every stack computes one `name_prefix` and one `common_tags` map and passes them down. That is how naming stays consistent (`clienta-dev-vpc`, `clienta-dev-eks-nodes-sg`) and how cost allocation works (`Client`, `Environment`, `Stack` tags on every resource). The `Stack` tag answers "which state file owns this" when you find a resource in the console.

### modules/network/vpc

One `aws_vpc` with DNS support and hostnames on. DNS hostnames are required for EKS, for interface endpoints' private DNS and for RDS endpoints to resolve; the module makes them defaults so nobody forgets.

### modules/network/subnets

```hcl
resource "aws_subnet" "public"      { count = length(var.public_subnet_cidrs)      map_public_ip_on_launch = true  ... Tier = "public" }
resource "aws_subnet" "private_app" { count = length(var.private_app_subnet_cidrs) map_public_ip_on_launch = false ... Tier = "private-app" }
resource "aws_subnet" "private_db"  { count = length(var.private_db_subnet_cidrs)  map_public_ip_on_launch = false ... Tier = "private-db" }
```

- **Three tiers** exactly as the AWS chapter describes: public for ALB and NAT, private-app for nodes and pods, private-db for RDS and ElastiCache with no NAT route by default.
- **Per-tier tag maps** carry `kubernetes.io/role/elb` (public) and `kubernetes.io/role/internal-elb` (private-app) so the AWS Load Balancer Controller can discover subnets, and `karpenter.sh/discovery` on the app subnets so Karpenter can find where to launch nodes. These tags are *contracts* with controllers; delete one and provisioning silently stops.
- **Sizing in the tfvars:** app subnets are `/20` (4096 IPs each) because pods consume VPC IPs; public subnets are `/26` because only load balancers and NAT live there; DB subnets are `/24`. That asymmetry is the IP-exhaustion lesson applied.
- **`count` indexed by position** is the known weakness: removing the first CIDR shifts every subnet and forces replacement. `for_each` keyed by AZ is the fix (see findings).

### modules/network/routing

```hcl
locals { nat_gateway_count = var.enable_nat_gateway ? (var.nat_gateway_mode == "single" ? 1 : length(var.public_subnet_ids)) : 0 }
resource "aws_eip" "nat"         { count = local.nat_gateway_count  domain = "vpc" }
resource "aws_nat_gateway" "this" { count = local.nat_gateway_count  depends_on = [aws_internet_gateway.this] }
resource "aws_route" "private_app_nat" {
  nat_gateway_id = var.nat_gateway_mode == "single" ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index % length(aws_nat_gateway.this)].id
}
resource "aws_route" "private_db_nat" { count = var.enable_db_subnet_nat_route && var.enable_nat_gateway ? length(var.private_db_subnet_ids) : 0 ... }
```

- **`nat_gateway_mode = single | per_az`** with a `validation` block on the variable. Single is the cost choice for dev; per-AZ is the availability choice for prod (one AZ's NAT failing must not black-hole the other AZs). The modulo in the route lets a per-AZ layout survive fewer NATs than subnets.
- **One route table per private subnet**, not one shared. That is what makes per-AZ NAT possible later without re-creating route tables.
- **DB subnets have no NAT route unless `enable_db_subnet_nat_route = true`.** Databases should not be able to reach the internet; the flag exists for the rare engine that needs it.
- **`depends_on` on the IGW** for the NAT gateway: an explicit dependency AWS requires (the NAT needs the IGW attached) that Terraform cannot infer from attributes.
- **The EIPs are the egress IPs partners allow-list.** They are created here and nowhere else, which is correct; what is missing is `prevent_destroy` on them.

### modules/security/security-groups

```hcl
resource "aws_security_group" "eks_cluster" {}   # control plane ENIs
resource "aws_security_group" "eks_nodes"   { tags = merge(..., { "karpenter.sh/discovery" = var.karpenter_discovery_tag_value }) }
resource "aws_security_group" "app"         {}
resource "aws_security_group" "db"          {}

resource "aws_security_group_rule" "eks_cluster_ingress_nodes_https" { from_port = 443  source_security_group_id = eks_nodes }
resource "aws_security_group_rule" "eks_nodes_ingress_cluster"       { from_port = 1025 to_port = 65535 source_security_group_id = eks_cluster }
resource "aws_security_group_rule" "eks_nodes_ingress_self"          { self = true protocol = "-1" }
resource "aws_security_group_rule" "db_ingress_postgresql_from_app"  { count = var.enable_postgresql_rule ? 1 : 0  source_security_group_id = app }
```

- **Separate `aws_security_group_rule` resources, not inline `ingress {}` blocks.** Inline rules and standalone rules fight each other; standalone rules can be added by other stacks without touching this one. (The newer `aws_vpc_security_group_ingress_rule` resources are better still; see findings.)
- **Node ↔ control plane rules are the EKS minimum:** nodes to API on 443, API to kubelets and webhooks on 1025 to 65535, node to node everything. Webhook-based admission controllers (Kyverno, the LB controller) fail with timeouts if the 1025+ rule is missing; that is the classic "my webhook times out" root cause.
- **App → DB on 3306/5432 by security-group reference, not CIDR.** Security groups as the primary control, CIDRs as the exception.
- **The `karpenter.sh/discovery` tag on the node SG** is the other half of the Karpenter contract; the `EC2NodeClass` selects security groups by this tag.
- **Egress is `0.0.0.0/0` everywhere** via `var.egress_cidr_blocks`. Fine for dev; a regulated prod would narrow it or add egress inspection.

## stacks/new-environment/02-eks-core/

### modules/iam/eks-roles

Two roles with partition-aware service principals (`eks.${dns_suffix}`, `ec2.${dns_suffix}`) and the three AWS-managed node policies. Notice:

```hcl
resource "aws_iam_role_policy_attachment" "nodes_cni_policy" { count = var.attach_cni_policy_to_node_role ? 1 : 0 ... }
```

The CNI policy on the *node* role is a bootstrap compromise: the CNI needs it before any IRSA role exists. The variable description says it: "for final hardened setup, move this to VPC CNI IRSA in 03-eks-platform". That is a documented TODO, not an oversight, and saying so in a review is the difference between nit-picking and understanding.

Also note `AmazonEC2ContainerRegistryPullOnly` instead of `ReadOnly`: the narrower, newer managed policy. Small signals like this show the author keeps up.

### modules/security/kms

```hcl
resource "aws_kms_key" "this" {
  enable_key_rotation = true
  policy = jsonencode({ Statement = [{ Sid = "EnableRootAccountPermissions", Principal = { AWS = "arn:...:iam::${account_id}:root" }, Action = "kms:*", Resource = "*" }] })
}
resource "aws_kms_alias" "this" { name = "alias/${var.alias_name}" }
```

- **Why a dedicated key per cluster.** EKS envelope-encrypts Secrets with it. One key per cluster means a dev key compromise cannot decrypt prod Secrets, and deleting a cluster can retire its key.
- **The root-only key policy** is the minimum that prevents an orphaned key; IAM policies then govern use. For a fintech you would add explicit key-admin and key-user statements and `kms:ViaService` conditions (see findings).
- **`deletion_window_in_days` as a variable (default 30)** and rotation on are the two things auditors check first.

### modules/eks/cluster

```hcl
resource "aws_eks_cluster" "this" {
  vpc_config { subnet_ids, security_group_ids, endpoint_private_access, endpoint_public_access, public_access_cidrs }
  encryption_config { provider { key_arn = var.kms_key_arn } resources = ["secrets"] }
  enabled_cluster_log_types = ["api","audit","authenticator","controllerManager","scheduler"]
  access_config { authentication_mode = "API"  bootstrap_cluster_creator_admin_permissions = false }
}
resource "aws_iam_openid_connect_provider" "this" { url = aws_eks_cluster.this.identity[0].oidc[0].issuer  client_id_list = ["sts.${dns_suffix}"] }
resource "aws_eks_access_entry" "cluster_admin"  { for_each = toset(var.cluster_admin_principal_arns) ... }
resource "aws_eks_access_policy_association" "cluster_admin" { policy_arn = ".../AmazonEKSClusterAdminPolicy"  access_scope { type = "cluster" } }
resource "aws_eks_access_entry" "developer" ... policy AmazonEKSEditPolicy, access_scope { type = "namespace" namespaces = var.developer_namespaces }
```

- **`authentication_mode = "API"`** means access entries only, no `aws-auth` ConfigMap. Every grant is a Terraform resource and a CloudTrail event. **`bootstrap_cluster_creator_admin_permissions = false`** removes the implicit admin for whoever ran `apply`; it is the single most audit-relevant line in the module. The trap: if `cluster_admin_principal_arns` is empty on first apply you have a cluster nobody can reach. The tfvars always pass at least the SSO admin role.
- **Four tiers of access** (cluster admin, platform admin, namespace-scoped developer edit, cluster-wide viewer) via `for_each` over principal lists. Namespace-scoped `AmazonEKSEditPolicy` is how developers get write access to their namespaces without any RBAC YAML.
- **All five control-plane log types on by default.** Audit logs are evidence; authenticator logs tie IAM identities to Kubernetes users.
- **OIDC provider created next to the cluster** so IRSA works from the first `03` apply. The thumbprint default is the well-known root CA thumbprint; EKS no longer strictly needs it but the provider argument is required.
- **Private endpoint on, public off by default**, with `public_access_cidrs` as the escape hatch. The dev tfvars turn public on for two office IPs; prod should not.

### modules/eks/managed-node-group

```hcl
resource "aws_launch_template" "this" {
  update_default_version = true
  metadata_options { http_tokens = "required"  http_put_response_hop_limit = var.imds_hop_limit  instance_metadata_tags = "disabled" }
  block_device_mappings { ebs { encrypted = true  volume_type = gp3 } }
  tag_specifications { resource_type = "instance" ... } ; { resource_type = "volume" ... }
}
resource "aws_eks_node_group" "this" {
  launch_template { id = aws_launch_template.this.id  version = aws_launch_template.this.latest_version }
  scaling_config { desired_size, min_size, max_size }
  update_config  { max_unavailable = var.max_unavailable }
  dynamic "taint" { for_each = var.taints ... }
}
```

- **Why a custom launch template at all.** Managed node groups give you a default one, but you cannot set IMDSv2-required, hop limit 1, encrypted gp3 root volumes or volume tags without your own template. Hop limit 1 is what stops pods from reaching the node's instance credentials; `http_tokens = required` is IMDSv2.
- **`version = latest_version` with `update_default_version = true`**: any template change rolls the node group (respecting `max_unavailable`). That is intended, but it means a tag change on the template is a node rotation; reviewers should know that.
- **This is the "system" pool.** Labels `nodepool=system`, `workload-type=platform`, on-demand, small and stable. Karpenter, CoreDNS, ArgoCD land here; Karpenter cannot run on nodes it provisions.
- **`scaling_config.desired_size` is managed by Terraform** with no `ignore_changes`. For a fixed system pool that is right; if a cluster-autoscaler ever managed this group you would add `lifecycle { ignore_changes = [scaling_config[0].desired_size] }`.

### modules/eks/addons

```hcl
resource "aws_eks_addon" "this" {
  for_each = var.addons
  addon_name = each.key
  addon_version            = try(each.value.addon_version, null)
  service_account_role_arn = try(each.value.service_account_role_arn, null)
  configuration_values     = try(each.value.configuration_values, null)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
}
```

- **A map of add-ons with optional attributes** (`optional()` in the variable type): one module serves core add-ons in 02 and storage add-ons in 03. `for_each` keyed by add-on name means adding `eks-pod-identity-agent` later touches nothing else.
- **`addon_version = null` lets EKS pick the default for the cluster version** (dev); prod tfvars pin explicit versions (`v1.22.3-eksbuild.1` etc.). That difference between dev and prod tfvars is deliberate and worth pointing out: float in dev to discover breakage, pin in prod to make upgrades explicit.
- **`OVERWRITE` on conflicts** makes Terraform the owner of the add-on configuration; manual `kubectl edit` of the aws-node DaemonSet gets reverted on the next apply. Correct for a platform team; mention that it is how you enforce "no console changes" for add-ons.
- **Ordering:** `depends_on = [module.eks_cluster, module.system_node_group]` so CoreDNS has nodes to schedule on; without nodes the add-on reports degraded and the apply waits on it.

## stacks/new-environment/03-eks-platform/

### modules/iam/karpenter

A hand-written controller policy, scoped the way the Karpenter docs recommend:

- `ec2:RunInstances`/`CreateFleet` limited to resource ARNs in the cluster's region; `ec2:TerminateInstances` only where `ec2:ResourceTag/karpenter.sh/discovery = <cluster>`; `iam:PassRole` only on the node role; instance-profile actions limited to the account; `eks:DescribeCluster` only on this cluster's ARN; `ssm:GetParameter` only under `/aws/service/*` (AMI lookups); pricing read.
- Trust policy is standard IRSA: `Federated = oidc_provider_arn`, `sts:AssumeRoleWithWebIdentity`, condition on `:aud = sts.amazonaws.com` and `:sub = system:serviceaccount:kube-system:karpenter`.

Why this matters in an interview: Karpenter is the most privileged controller on the cluster (it launches and terminates EC2). A policy that can only terminate instances it tagged is the blast-radius control; `Resource = "*"` on `TerminateInstances` would let a compromised controller kill the system node group or unrelated instances.

### modules/eks/karpenter

```hcl
resource "helm_release" "karpenter" { repository = "oci://public.ecr.aws/karpenter"  version = var.chart_version  wait = true  timeout = 600
  values = [yamlencode({ serviceAccount = { annotations = { "eks.amazonaws.com/role-arn" = var.controller_role_arn } }, settings = { clusterName, clusterEndpoint }, replicas = var.replicas })] }

locals {
  ec2nodeclasses_yaml = templatefile("${path.module}/templates/ec2nodeclasses.yaml.tpl", { client_name, cluster_name, node_role_name, ami_alias })
  ec2nodeclass_documents = { for i, m in compact(split("---", local.ec2nodeclasses_yaml)) : i => trimspace(m) if trimspace(m) != "" }
}
resource "kubectl_manifest" "ec2nodeclasses" { for_each = local.ec2nodeclass_documents  yaml_body = each.value  depends_on = [helm_release.karpenter] }
resource "kubectl_manifest" "nodepools"      { for_each = local.nodepool_documents      depends_on = [kubectl_manifest.ec2nodeclasses] }
resource "aws_eks_access_entry" "karpenter_node_role" { count = var.create_node_role_access_entry ? 1 : 0  type = "EC2_LINUX" }
```

- **Helm for the controller, `kubectl_manifest` for the CRs**, split with `depends_on` so CRDs exist before `NodePool`s are applied. The `split("---")` trick turns one multi-document template into a `for_each` map; it works but keys are positional (index 0, 1, 2), so re-ordering the template re-creates NodePools. Keying by `metadata.name` is the improvement.
- **`EC2_LINUX` access entry for the node role** lets Karpenter-launched nodes join the cluster under API authentication mode. It is behind a flag because the managed node group's role already has one when the same role is reused (duplicate access entry is an error).
- **The templates encode the node strategy:** an `EC2NodeClass` with IMDSv2 required, hop limit 1, encrypted gp3 100 GiB root, AMI by alias; a `default-on-demand` pool, a `general-purpose` pool with `expireAfter: 120h` and `limits` (cpu 1000, memory 1000Gi) as the runaway-scaling guard, and a tainted `devops-infra` pool with `WhenEmpty` consolidation for platform components. Three pools, three disruption policies: that is the "stable pool" idea from the Karpenter churn incident baked into the template.
- **What a reviewer flags:** `amiSelectorTerms: alias: al2023@latest` (nodes silently rotate on every AMI release; pin `al2023@v2025xxxx`), `consolidateAfter: 30s` on the general pool (aggressive; the incident lesson), no `budgets` on disruption, no spot pool yet. All in findings.

### modules/iam/aws-load-balancer-controller and modules/eks/aws-load-balancer-controller

IAM policy is the upstream controller policy (ELB CRUD, SG management, WAF/Shield association, service-linked role creation gated by `iam:AWSServiceName`), trust is IRSA. The Helm release passes `clusterName`, `region`, `vpcId` (so the controller does not need IMDS), the annotated service account, replica count, node selector and tolerations. `depends_on = [module.karpenter, ...]` in the stack so the controller has capacity to schedule on.

### modules/iam/irsa-role

```hcl
Condition = { (var.condition_operator) = {
  "${oidc_host}:aud" = "sts.amazonaws.com"
  "${oidc_host}:sub" = var.service_account_subjects   # list → StringEquals/StringLike
} }
```

A generic IRSA role: `StringEquals` for an exact service account, `StringLike` with a wildcard subject (`system:serviceaccount:kube-system:efs-csi-*`) for drivers that run several SAs. The `validation` block only allows those two operators. This is the module every application IRSA role should go through, so trust policies are never hand-written.

### CSI add-ons and ArgoCD

`ebs_csi_irsa` + `efs_csi_irsa` + `storage_addons` (EBS and EFS CSI as EKS add-ons with `service_account_role_arn`) then `argocd` (Helm, `ClusterIP`, `server.insecure` configurable for TLS-terminating ingress, node selector and tolerations so it can be pinned to the infra pool). `depends_on = [module.karpenter, module.storage_addons]` so ArgoCD's Redis has storage and nodes. The optional `kubectl_manifest "argocd_helm_repo_secret"` registers the Helm-values repo (label `argocd.argoproj.io/secret-type: repository`), gated on both username and password being non-empty.

**Why ArgoCD is the last thing Terraform installs.** From here on, workloads are GitOps. Terraform owns what needs AWS IAM or exists before the cluster has a GitOps engine; ArgoCD owns everything that is "just Kubernetes YAML". That line is the subject of [What-To-Use-Terraform-For.md](../What-To-Use-Terraform-For.md).

## stacks/application-stack/

```hcl
resource "random_password" "rds_postgres" { count = var.create_rds_postgres ? 1 : 0  length = 16  special = false }
locals {
  name_prefix = var.service != "" ? "${client}-${lower(product)}-${lower(service)}" : "${client}-${lower(product)}"
  s3_name  = var.s3_bucket_name != "" ? var.s3_bucket_name : "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"
  rds_postgres_password = var.rds_postgres_password != "" ? var.rds_postgres_password : random_password.rds_postgres[0].result
}
module "rds_postgres" { count = var.create_rds_postgres ? 1 : 0  source = "../../modules/rds-postgres" ... }
module "dns"          { for_each = var.create_dns && local.alb_dns_name != "" ? toset(var.service_hostnames) : toset([]) ... }
```

- **Feature-flagged composition.** One stack, `create_*` booleans, each sub-module behind `count = flag ? 1 : 0`. The wrapper roots are ten lines. Outputs guard with `length(module.x) > 0 ? module.x[0].attr : ""` so a disabled module does not break outputs.
- **Naming convention in one place.** `client-product-service` prefix, account ID appended to bucket names for global uniqueness, environment appended to queue names. Consistency here is what makes cost tags and dashboards work later.
- **Generated passwords with an override.** Better than requiring a password variable; still lands in state (see findings for the `manage_master_user_password` fix).
- **`data "aws_lb" "existing"`** lets a service attach DNS to an ALB created elsewhere (the shared internal ALB pattern) instead of forcing one ALB per service.
- **`eks_security_group_ids` from the network remote state** feed the RDS/ElastiCache security groups so pods can reach databases by SG reference, not CIDR.
- **Smell to name:** the stack has its own `provider "aws"` block in `versions.tf`, which blocks `count`/`for_each` on the stack and multi-region use; providers belong in the root.

## Leaf modules worth a sentence each

- **rds-postgres / rds-mysql:** subnet group, own security group (VPC CIDR plus EKS SGs, `create_before_destroy`), parameter group derived from the engine major version (`postgres${split(".", version)[0]}`, `mysql8.0`) with connection or slow-query logging on, `storage_encrypted = true`, gp3, backup retention variable, `skip_final_snapshot` and `deletion_protection` as variables. Review targets: defaults of `skip_final_snapshot = true` and `deletion_protection = false` in the stack, no `multi_az`, no `performance_insights_enabled`, password in state, default KMS key.
- **s3-bucket:** versioning toggle, SSE-KMS with bucket key, public access block. Missing TLS-only bucket policy and lifecycle rules. Note `tags` is a variable but not applied to the bucket (a real bug to spot).
- **sqs-queue:** DLQ created first with 14-day retention, main queue with `redrive_policy` referencing it, SSE with the AWS-managed key. A DLQ by default is a good opinion.
- **ecr:** scan on push, lifecycle policy keeping the last N `sha`/`main`/`release` tags and expiring untagged after 7 days. `image_tag_mutability = "MUTABLE"` is the finding (immutable tags are a supply-chain control).
- **alb:** ALB plus three target groups and three HTTP listeners for a specific legacy product (app, control plane, orchestrator ports), `target_type = instance`. Product-specific and HTTP-only; not the module you would reuse for EKS ingress, which the LB controller handles.
- **route53:** ALIAS A record or CNAME behind a `record_type` switch, `evaluate_target_health = true`.
- **elasticache-redis:** subnet group, SG, replication group with `num_replicas` (0 = single node).
- **emr-cluster:** `ignore_changes` on core instance count and EBS config because EMR managed scaling edits them; a correct use of `ignore_changes` with an obvious owner.
- **solr, ra:** EC2 workloads with `user_data` templates (`templatefile`) that fetch `.env` from Secrets Manager via IMDSv2 and log into ECR at boot. Terraform builds the box; the bootstrap script configures it. This is the boundary with Ansible/Packer discussed in What-To-Use-Terraform-For.
- **hybrid-vpc:** adds only the subnets, IGW and NATs listed in `var.missing_components` to an *existing* VPC, deriving CIDRs with `cidrsubnet()`. The pattern for adopting a client-provided VPC without touching what is there.
- **modules/eks/main.tf (monolith):** the older all-in-one EKS module (roles, cluster, node group in one file, `ReadOnly` ECR policy, inline `arn:aws:` without partition). Superseded by the split modules; still in the tree. "Delete or mark deprecated" is the review ask.

## environments/clienta/import-existing/

Terraform 1.5+ `import {}` blocks for a VPC, subnets, IGW, EIPs, NAT gateways, route tables and associations that were built by hand, paired with resource blocks that describe them. Run `terraform plan`, iterate until it shows no changes, apply to write state, then start converging. Hardcoded IDs in the file are acceptable for a one-time adoption root; the finding is the hardcoded `profile` and that this root should be deleted or archived after adoption.
