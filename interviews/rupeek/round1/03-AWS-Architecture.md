# Rupeek Round 1 — AWS architecture depth

> Account structure and SCPs, VPC and CIDR planning for EKS, IAM and workload identity (IRSA vs Pod Identity), RDS/Aurora, S3 and KMS posture, multi-AZ vs multi-region with India data residency.

---

The JD says "deep AWS": VPC design, IAM, EKS, RDS/Aurora, S3, KMS, cost architecture, multi-AZ vs multi-region. For a lending platform the hidden sub-text is: data stays in India, every access is attributable, blast radius is bounded by account and role, and the database tier survives an AZ loss without a human.

## Account structure first

Before VPCs, say how you would lay out accounts, because everything else inherits from it.

- **AWS Organizations** with OUs: `security` (log archive, audit/security tooling), `infrastructure` (shared services: CI, Terraform state, transit, DNS), `workloads/prod`, `workloads/non-prod`, `sandbox`. Rupeek has two legal entities (RFPL, RCPL), so likely an OU or account boundary per entity for regulatory separation.
- **Service Control Policies** as guardrails that even admins cannot bypass: deny regions outside `ap-south-1`/`ap-south-2` (data localisation), deny disabling CloudTrail/GuardDuty/Config, deny leaving the organisation, deny root user actions, require IMDSv2, deny creation of IAM users in workload accounts.
- **Identity Center (SSO)** with permission sets; no IAM users; break-glass roles with alerting. CloudTrail organisation trail into the log-archive account with object lock. AWS Config aggregator, GuardDuty, Security Hub delegated to the security account.
- Prod and non-prod never share an account, a VPC or a KMS key.

## VPC design

**Subnet tiering per AZ (three AZs in Mumbai):**
- **Public**: only load balancers and NAT gateways. No compute.
- **Private (nodes/apps)**: EKS worker nodes, pods, internal ALBs. Egress via NAT.
- **Data / isolated**: RDS, ElastiCache, no route to NAT at all. Reached only from the app subnets' security groups.
- Optionally a **management** or **endpoint** tier for VPC interface endpoints.

**CIDR planning for EKS is where candidates get caught.** The VPC CNI gives every pod a real VPC IP from the node's subnet. A `/24` per AZ is exhausted by a few dozen nodes. Plan the node subnets large (`/20` or `/19` each) and plan the VPC from a company-wide IP allocation so VPC peering/Transit Gateway never collides. If you inherit small subnets, the escape hatches are:
- **Secondary CIDR** on the VPC (including the `100.64.0.0/10` carrier-grade NAT range) with pod subnets there, using **custom networking** (`ENIConfig` per AZ) so pods get IPs from the secondary range while nodes stay in the primary.
- **Prefix delegation** (`ENABLE_PREFIX_DELEGATION=true`): the CNI assigns `/28` prefixes to ENIs instead of individual IPs, which raises pods-per-node and lowers EC2 API churn. Requires nitro instances and contiguous free space in the subnet (fragmented subnets break it).
- Tune `WARM_PREFIX_TARGET`, `WARM_IP_TARGET`, `MINIMUM_IP_TARGET` so the CNI does not hoard IPs on small subnets.
- Dual-stack IPv6 for pods removes exhaustion entirely but needs every dependency (RDS endpoints, third parties) to be reachable; realistic for new clusters, not a retrofit.

**Routing and egress:**
- One NAT gateway **per AZ**, not one shared. A single NAT is an AZ-level single point of failure and makes every cross-AZ byte billable. Egress IPs are what partner banks and NPCI/UPI allow-list, so NAT EIPs are long-lived, documented assets; changing them is a change ticket with partner notice.
- **VPC endpoints** for S3 and DynamoDB (gateway, free) always; interface endpoints for ECR (`api` and `dkr`), STS, Secrets Manager, KMS, CloudWatch Logs, SSM, EC2 at minimum. They cut NAT data-processing cost and keep traffic off the internet, which is an audit answer too.
- **Transit Gateway** for multi-VPC/multi-account; peering only for two or three VPCs. Centralised egress VPC with inspection (Network Firewall) is the regulated-industry pattern when Infosec asks for egress filtering.
- VPC Flow Logs to S3 (or CloudWatch) with retention: this is required evidence for most audits.
- Security groups are the primary control; NACLs stateless and coarse (block known-bad ranges, protect the data tier).

**EKS-specific networking:** private API endpoint (public disabled or restricted to office/VPN CIDRs); cluster security group vs node security group; subnet tags `kubernetes.io/role/internal-elb` and `kubernetes.io/role/elb` so the AWS Load Balancer Controller discovers subnets; the cluster needs at least two AZs' subnets for the control-plane ENIs; `ip-prefix` vs `ip` target type on ALB (`ip` targets pods directly and avoids the NodePort hop).

## IAM

**Principles you should state unprompted:** no humans with long-lived keys, no IAM users in workload accounts, roles with session durations and MFA, least privilege proven by **Access Analyzer** and **CloudTrail last-accessed** data, permission boundaries on anything that can create roles, and separation between the CI role that plans (read-only) and the one that applies.

**Policy mechanics to be fluent in:** identity vs resource policies and how they combine across accounts (both must allow cross-account); explicit deny wins; SCPs and permission boundaries only **limit**, never grant; session policies; condition keys that matter (`aws:PrincipalOrgID`, `aws:SourceVpce`, `aws:SecureTransport`, `kms:ViaService`, `aws:RequestedRegion`, `aws:ResourceTag`/`aws:PrincipalTag` for ABAC); `iam:PassRole` as the classic privilege-escalation path; `sts:AssumeRole` trust policies with `ExternalId` for third parties.

**Workload identity on EKS:**
- **IRSA (IAM Roles for Service Accounts):** the cluster's OIDC issuer is registered as an identity provider in IAM; a role trusts `system:serviceaccount:<ns>:<sa>` via the `sub` claim; the pod gets a projected service-account token; the SDK exchanges it with `AssumeRoleWithWebIdentity`. Works everywhere (including self-managed Kubernetes), requires the OIDC provider per cluster and the audience `sts.amazonaws.com`.
- **EKS Pod Identity (2023+):** an EKS-managed agent (DaemonSet add-on) and an **association** between a role and a namespace/service account; the role trusts `pods.eks.amazonaws.com`. No OIDC provider per cluster, roles reusable across clusters, supports session tags for ABAC. Does not work for workloads outside EKS (Fargate support came later; check current status) and some add-ons still assume IRSA.
- **Node instance role** must be minimal (CNI, ECR pull, SSM); the CNI itself should use IRSA/Pod Identity so the node role is not powerful. Block pods from the instance metadata (IMDS hop limit 1 or network policy) so a pod cannot steal node credentials.

> **Have an opinion:** New clusters: Pod Identity for application workloads (simpler trust policy, cross-cluster reuse, ABAC via session tags) and IRSA for add-ons that still require it; existing clusters stay on IRSA until an upgrade window. Either way: one role per service, scoped to named resources, no `*`.

**IAM review habits a tech lead installs:** every new policy goes through Access Analyzer policy validation in CI; `iam:*`, `*:*`, `Resource: "*"` on write actions fail the PR; roles are created by the IRSA module, never by hand; quarterly unused-role cleanup from last-accessed data (this is also an audit control).

## EKS from the AWS side

- Control plane is AWS-managed and multi-AZ; you pay per cluster-hour plus nodes. Extended support pricing kicks in after standard support ends for a version (roughly 14 months), which is a cost **and** compliance argument for staying current.
- **Access entries** (replacing the `aws-auth` ConfigMap) map IAM principals to Kubernetes groups or EKS access policies (`AmazonEKSClusterAdminPolicy`, `AmazonEKSViewPolicy`). Managed in Terraform, auditable in CloudTrail. The cluster creator's implicit admin is a trap: disable `bootstrap_cluster_creator_admin_permissions` and grant explicitly.
- **Control plane logging** (api, audit, authenticator, controllerManager, scheduler) to CloudWatch; audit logs are required evidence and the way you answer "who deleted that deployment".
- **Envelope encryption of secrets** with a KMS key (now default on new clusters). Say it anyway.
- **Cluster endpoint**: private; if public is needed restrict CIDRs. Access from CI via VPN/VPC or a bastion-less SSM port forward.
- **Fargate**: fine for isolated batch or for not wanting nodes at all; costly and constrained (no DaemonSets, no GPUs, slower starts) for a general platform. **EKS Auto Mode** (late 2024): AWS runs Karpenter, CNI, CSI, LB controller for you with a premium on compute; worth stating a view (good for small teams, less control over add-on versions and node AMIs, which matters when Infosec wants CIS-hardened AMIs).

## RDS and Aurora

**Multi-AZ vs read replicas:** Multi-AZ (RDS) is a synchronous standby in another AZ for **availability**; failover is DNS-based and takes 60 to 120 seconds; the standby serves no reads. **Multi-AZ DB cluster** (RDS, two readable standbys, semi-sync) and **Aurora** (shared storage across three AZs, six copies, replicas promote in about 30 seconds, reader endpoint) blur that line. Read replicas (async) are for **read scaling** and cross-region DR, with replication lag as the cost.

**Aurora specifics worth knowing:** storage auto-grows and is billed per GB plus I/O (or I/O-Optimized for heavy write workloads, often cheaper above ~25% I/O share of cost); writer and reader endpoints plus custom endpoints; failover priority tiers; Aurora Global Database for cross-region with about one second lag and managed failover/switchover; Serverless v2 for spiky or non-prod workloads (ACU min/max, scales in seconds, pause support returned in 2024); backtrack (MySQL) and point-in-time restore; Blue/Green deployments for major version upgrades with minimal downtime; RDS Proxy for connection pooling in front of bursty app pods (Lambda-style churn, failover smoothing).

**Operational hygiene they will test:** parameter groups in Terraform (not console), `apply_immediately` false in prod, maintenance windows aligned to low traffic, automated backups retention (35 days max; longer via AWS Backup with vault lock for audit), snapshots copied cross-region and cross-account for ransomware resilience, encryption with a CMK and the implication that you cannot turn encryption on later without a snapshot copy, Performance Insights and Enhanced Monitoring on, `deletion_protection` and `prevent_destroy`, minor version auto-upgrade decided deliberately, IAM database authentication where the driver supports it, secrets rotated via the RDS-managed Secrets Manager integration.

**Major version upgrades:** test on a snapshot-restored instance, check extensions and parameter group compatibility, use Blue/Green (Aurora and RDS MySQL/Postgres) or a replica-promote approach, rehearse rollback, and schedule with product because connections drop at switchover.

**For a ledger system:** the ledger wants strict durability and auditability, which pushes toward Aurora PostgreSQL with Multi-AZ, synchronous commits, PITR plus long-retention immutable backups, no shared credentials, and row-level access logging (pgAudit) because auditors ask who read what.

## S3 and KMS

**S3 posture that passes audits:** account-level and bucket-level Block Public Access; bucket policy denying `aws:SecureTransport=false` and enforcing `s3:x-amz-server-side-encryption` with the right key; SSE-KMS with a bucket key (cuts KMS cost by caching the data key); versioning plus Object Lock (compliance mode) for audit logs and evidence buckets; access logging or CloudTrail data events; lifecycle rules (Standard to IA to Glacier, expire noncurrent versions, abort incomplete multipart uploads); replication to another region/account for DR with the destination in India; `aws:PrincipalOrgID` conditions on cross-account access; VPC endpoint policies restricting which buckets can be reached from the VPC (data exfiltration control); presigned URLs with short expiry for customer document access (KYC documents, gold valuation images).

**KMS design:**
- Customer-managed keys (CMKs) per data classification and per environment, not one key for everything, so a compromised role in dev cannot decrypt prod. Key policy is the root of trust; IAM policies alone cannot grant use of a key unless the key policy delegates to IAM.
- Grants vs key policy; `kms:ViaService` conditions so a key can only be used through S3 or RDS; `kms:EncryptionContext` for sensitive buckets.
- Automatic annual rotation on (rotates backing key, old data still decrypts); multi-region keys for cross-region replication of encrypted data; aliases in Terraform; deletion is a 7 to 30 day waiting period and should be alarmed on.
- Cost: per key per month plus per request; bucket keys and data key caching in SDKs matter at scale.
- Compliance phrasing: "encryption at rest with customer-managed keys, key policies reviewed quarterly, CloudTrail logs every `Decrypt`". CloudHSM only if a regulator demands FIPS 140-2 Level 3 single-tenant control; otherwise KMS.

## Multi-AZ and multi-region trade-offs

**Multi-AZ is the default and is not optional for prod.** Three AZs for EKS nodes and RDS; topology spread constraints and PDBs so a single AZ loss keeps capacity; per-AZ NAT; be aware of cross-AZ data transfer charges and use topology-aware routing where chatty services justify it.

**Multi-region is a business decision** expressed in RPO/RTO. The levels, with cost and complexity rising:
1. **Backup and restore**: snapshots and IaC in the second region; RTO hours, RPO up to a day. Cheapest; most companies' real posture.
2. **Pilot light**: data replicated continuously (Aurora Global Database, S3 CRR), minimal compute pre-provisioned; RTO tens of minutes.
3. **Warm standby**: scaled-down full stack running; RTO minutes.
4. **Active-active**: both regions serve traffic; needs conflict-free data design, global routing (Route 53 health checks, Global Accelerator), and is rarely justified for a lending core.

**India-specific constraints:** RBI expects data localisation (payment system data stored only in India) and a tested DR with a defined RPO/RTO for critical systems; the realistic pair is `ap-south-1` (Mumbai) primary and `ap-south-2` (Hyderabad) DR. Not every service exists in Hyderabad on day one; check service availability before promising it. DR drills twice a year with evidence (screenshots, timings, sign-off) are an audit item; the drill, not the diagram, is what the auditor wants.

> **Have an opinion:** "Multi-AZ everywhere, pilot light in Hyderabad for the lending core and ledger with Aurora Global Database and S3 replication, backup-and-restore for everything else, and a quarterly restore test that proves the backup is real. Active-active is a cost I would push back on unless the business shows me the revenue per hour that justifies it."

## Cost architecture (the design-time part)

Cost governance has its own chapter, but at the architecture stage the decisions that dominate the bill are: NAT gateway data processing (fix with endpoints and per-AZ NAT), cross-AZ traffic (fix with topology-aware routing and AZ-local replicas), over-provisioned RDS (fix with Graviton, right sizing, Serverless v2 in non-prod, I/O-Optimized when appropriate), idle EKS nodes (fix with Karpenter consolidation and bin-packing), untagged resources (fix at creation with policy), and logging volume (fix with sampling, retention and log tiering). Say these at design time and the interviewer hears "this person has paid for mistakes".

## Interview questions and model answers

### Q1: Design the VPC for a new EKS cluster in Mumbai.

Three AZs. VPC `/16` from the company IPAM. Per AZ: public `/24` (ALB, NAT), private node/pod `/20`, data `/24` with no NAT route. Per-AZ NAT with documented EIPs for partner allow-lists. Gateway endpoints for S3 and DynamoDB, interface endpoints for ECR, STS, Secrets Manager, KMS, Logs, SSM. Flow Logs to S3. EKS private endpoint, subnets tagged for the LB controller. Prefix delegation on from day one; if IP pressure appears later, secondary CIDR with custom networking. Security groups as primary control; NACLs on the data tier.

---

### Q2: Explain IRSA end to end and contrast with Pod Identity.

EKS exposes an OIDC issuer; you register it in IAM; a role's trust policy allows `AssumeRoleWithWebIdentity` for `sub = system:serviceaccount:ns:sa`; the pod mounts a projected token with audience `sts.amazonaws.com`; the SDK's credential chain finds `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` and gets temporary credentials. Pod Identity instead uses an EKS agent and an association resource; the trust is to `pods.eks.amazonaws.com`; no per-cluster OIDC provider, easier multi-cluster reuse, session tags. I would use Pod Identity for apps on new clusters and keep IRSA for add-ons that need it.

---

### Q3: Multi-AZ RDS vs Aurora for a ledger database?

Aurora PostgreSQL: storage replicated six ways across three AZs, replica promotion around 30 seconds versus 1 to 2 minutes for RDS Multi-AZ, reader endpoint for reporting, Global Database for Hyderabad DR with about one second lag, Blue/Green for major upgrades. Pair with PITR, long-retention immutable backups via AWS Backup vault lock, pgAudit, CMK encryption, IAM auth or rotated secrets. RDS Multi-AZ remains fine for smaller or non-critical services where Aurora's I/O pricing does not pay off.

---

### Q4: How do you prevent data from leaving India?

SCP denying all regions except ap-south-1 and ap-south-2 (with the global-service exceptions IAM, CloudFront, Route 53, Organizations). S3 bucket policies and replication only to Indian regions. VPC endpoint policies restricting reachable buckets. KMS keys regional. Vendor review for SaaS that processes data. AWS Config rules to detect anything outside region. Evidence: the SCP document and Config compliance reports.

---

### Q5: What does a KMS key policy need to look like for an application bucket?

Root account as administrator (so the key is never orphaned), a key-admin role with manage but not use, usage granted to the specific application role and the S3 service via `kms:ViaService`, CloudTrail logging implicit. Separate keys per environment and data class, rotation enabled, alias managed in Terraform, deletion alarmed. Bucket policy requires that key's ARN in the encryption header.

---

### Q6: A partner bank needs to allow-list our egress IPs. What changes in your design?

NAT gateway EIPs become managed assets: allocated in Terraform with `prevent_destroy`, documented, one per AZ, and a change process with partner notice if they ever change. Alternatively route partner traffic through a dedicated egress VPC or NLB-backed static IPs. Monitor NAT health per AZ because losing one AZ's NAT now also means losing one allow-listed IP.

---

### Q7: How do you choose between VPC peering, Transit Gateway and PrivateLink?

Peering for two or three VPCs with no transitive need. Transit Gateway when there are many VPCs or accounts, for hub-and-spoke with centralised egress and inspection, at a per-attachment and per-GB price. PrivateLink to expose one service to another account or to a partner without routing whole networks, which is the clean answer for exposing an API to a lender partner inside AWS.

---

### Q8: What are the EKS control-plane logs and why do they matter?

api, audit, authenticator, controllerManager, scheduler to CloudWatch. Audit is the one auditors and incident responders want: who did what to which object. Authenticator ties IAM identities to Kubernetes users. Costs are driven by audit volume; keep it on in prod regardless and set retention to the compliance requirement.

---

### Q9: Explain Savings Plans vs Reserved Instances for an EKS-heavy estate.

Compute Savings Plans cover EC2 across families, sizes, regions and also Fargate and Lambda, which fits Karpenter's instance diversity; EC2 Instance Savings Plans and RIs are cheaper but lock family and region. RDS, ElastiCache and OpenSearch need their own RIs. Commit to the baseline you have measured over 60 to 90 days at roughly 70 to 80 percent of steady state; leave spot and on-demand for the rest; review quarterly.

---

### Q10: How do you give developers AWS access safely?

Identity Center with permission sets per role (read-only in prod for most, write in dev scoped by tags or by account), short sessions, MFA, no IAM users, CloudTrail queries available via Athena for self-service "what did I do". Break-glass role with approval and alerting. Kubernetes access via access entries mapped to the same groups so RBAC and IAM agree.

---
