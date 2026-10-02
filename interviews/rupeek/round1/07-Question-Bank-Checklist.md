# Rupeek Round 1 — Question bank, whiteboard prompts and checklist

> About 75 rapid-fire questions with one-line answers, whiteboard prompts, questions to ask the panel, a day-before checklist and a one-page cheat sheet.

---

## Rapid-fire: Terraform

- **What is in a Terraform state file and why is it sensitive?** Resource addresses to IDs and attributes, including secrets in plaintext.
- **Difference between `terraform refresh` and drift detection?** Refresh updates state from reality; drift detection compares reality to code and reports.
- **When is `count` acceptable?** Boolean on/off only; collections use `for_each`.
- **What does `-detailed-exitcode` do?** Exit 2 when the plan has changes; used by drift cron jobs.
- **What is the lock file for?** Pins provider versions and hashes per platform so CI and laptops agree.
- **`moved` block vs `state mv`?** Same effect; `moved` is declarative, reviewed in the PR, and replayable.
- **What happens if two people apply at once without locking?** Last writer wins; state corruption or duplicated resources.
- **How do you reference an output of another stack?** `terraform_remote_state` or SSM parameters; prefer SSM to decouple.
- **Why not provider blocks in modules?** Blocks `count`/`for_each` on the module, breaks multi-region composition.
- **What does `sensitive = true` protect?** CLI output only; state still has the value.
- **How do you test a module without creating resources?** `terraform test` with mock providers (1.7+); validate and tflint for syntax.
- **Plan says 1 to add, 1 to destroy for an S3 bucket. Risk?** Replacement deletes data; find the forcing attribute, use `prevent_destroy`.
- **What is a permission boundary and how does it relate to Terraform CI?** Caps what a role can grant; attach to the CI role so it cannot create admin roles.
- **Pessimistic constraint `~> 5.40`?** Allows 5.40 up to but not including 6.0.
- **What is Terragrunt for?** DRY backend and provider generation, dependency ordering, run-all across stacks.
- **How do you retire a module safely?** Deprecate with a version, migrate callers with `moved`, remove after all roots are off it.
- **What is Infracost?** Cost estimate of the plan posted on the PR; used as a gate.
- **What is checkov's `skip` and how do you govern it?** Inline suppression; must carry a justification and an expiry, reviewed monthly.
- **How does Atlantis authenticate to AWS?** A role assumed via OIDC or instance profile; no static keys; per-repo and per-directory roles possible.
- **How would you store Terraform state for a client who forbids S3?** Terraform Enterprise/HCP workspaces, or a self-hosted backend; the client's own tooling if mandated.

## Rapid-fire: AWS

- **Why per-AZ NAT?** Removes an AZ-level SPOF and cross-AZ data charges.
- **Gateway vs interface endpoints?** Gateway: S3 and DynamoDB, free, route-table based. Interface: ENI with private DNS, hourly plus per GB.
- **Explicit deny vs SCP vs permission boundary?** All three only restrict; explicit deny anywhere wins; SCP applies to the whole account; boundary applies to a principal.
- **Cross-account S3 access needs what?** Allow in the bucket policy and in the caller's identity policy; KMS key policy too if encrypted.
- **How do you block IMDSv1?** Launch template `http_tokens = required`; SCP condition `ec2:MetadataHttpTokens`.
- **Aurora failover time?** Roughly 30 seconds; RDS Multi-AZ 60 to 120 seconds; apps need retry and short DNS TTL.
- **What is RDS Proxy for?** Connection pooling and smoother failover for many short-lived connections.
- **Can you enable encryption on an existing unencrypted RDS?** No; snapshot, copy encrypted, restore.
- **S3 bucket key?** Caches a bucket-level KMS data key to reduce KMS calls and cost.
- **Object Lock modes?** Governance (privileged users can override) and Compliance (nobody can, including root).
- **KMS key policy vs IAM policy?** Key policy is authoritative; IAM only works if the key policy delegates.
- **What does `kms:ViaService` do?** Limits key use to calls made through a specific service such as S3 or RDS.
- **Route 53 failover vs Global Accelerator?** DNS failover depends on TTL and resolvers; Global Accelerator uses anycast IPs and shifts in seconds.
- **What is a Transit Gateway route table used for?** Segmentation: prod and non-prod attachments cannot reach each other.
- **How do you find who deleted a resource?** CloudTrail event history or Athena on the organisation trail; EKS audit log for Kubernetes objects.
- **What is Access Analyzer?** Finds resources shared outside the zone of trust and validates policies; generates least-privilege policies from CloudTrail.
- **Why Identity Center over IAM users?** Short-lived credentials, central MFA, permission sets, one place to offboard.
- **What is extended support on EKS and RDS?** Paid support after the standard window; a cost and audit reason to stay current.
- **Which AWS regions are in India?** ap-south-1 Mumbai, ap-south-2 Hyderabad; check service availability in Hyderabad.
- **How does ALB `ip` target type differ from `instance`?** Targets pod IPs directly, avoiding the NodePort hop and kube-proxy; needs the LB controller.

## Rapid-fire: EKS and Kubernetes

- **Kubelet version skew rule?** Up to three minors behind the API server, never ahead.
- **Why does Karpenter need a node it does not manage?** It cannot schedule itself onto a node that only exists after it runs.
- **What is a NodeClaim?** Karpenter's representation of one provisioned node.
- **`WhenEmpty` vs `WhenEmptyOrUnderutilized`?** Only remove empty nodes versus actively repack and replace under-utilised ones.
- **`karpenter.sh/do-not-disrupt`?** Pod or node annotation that blocks voluntary disruption; use on singletons and jobs.
- **PDB `minAvailable` equals replicas: effect?** Nothing can ever be evicted; drains and upgrades block.
- **What are the PSA levels?** privileged, baseline, restricted; modes enforce, audit, warn.
- **Mutating or validating first?** Mutating webhooks run first, then schema validation, then validating webhooks.
- **Why prefer ValidatingAdmissionPolicy for some rules?** In-tree CEL, no webhook availability or latency risk.
- **What does prefix delegation change?** ENIs get `/28` prefixes; more pods per node; needs nitro and unfragmented subnets.
- **`ndots:5` problem?** External names are tried with up to five search suffixes first; fix with trailing dot or lower ndots.
- **NodeLocal DNSCache benefit?** Cuts conntrack entries and CoreDNS load; DNS over TCP upstream.
- **Exit code 137 vs 143?** 137 SIGKILL (OOM or forced); 143 SIGTERM (graceful stop).
- **QoS classes and eviction order?** BestEffort first, then Burstable above request, Guaranteed last.
- **What is PLEG?** Kubelet's pod lifecycle relist loop; slow relist marks the node NotReady.
- **Where do EKS audit logs go?** CloudWatch Logs, when enabled per cluster.
- **etcd size limit on EKS?** 8 GB; cluster becomes read-only beyond it.
- **How do you see API server throttling?** `apiserver_flowcontrol_rejected_requests_total`, client 429s, audit by userAgent.
- **Access entries vs aws-auth?** Access entries are the IAM-managed, auditable replacement for the ConfigMap.
- **Topology spread vs anti-affinity?** Spread balances across zones or nodes with a skew; anti-affinity forbids co-location.
- **Why a `preStop` sleep?** Lets the load balancer deregister before the pod stops accepting connections.
- **How do you restrict pods from IMDS?** Hop limit 1 on the node, or a network policy to 169.254.169.254.
- **EBS volume and AZ?** EBS is AZ-bound; the pod must schedule in that AZ; use `WaitForFirstConsumer`.
- **Security groups for pods: use case?** VPC-level control of one workload reaching a database.
- **What does `ttlSecondsAfterFinished` solve?** Finished Jobs accumulating in etcd.

## Rapid-fire: cost

- **Top three cost surprises on EKS?** Over-requested pods, NAT data processing, logs and metrics volume.
- **gp2 to gp3 saving?** About 20 percent plus decoupled IOPS and throughput.
- **Compute Savings Plan vs EC2 Instance SP?** Compute is flexible across family, region, Fargate, Lambda; Instance SP cheaper but locked.
- **How does Kubecost attribute shared cost?** Idle and shared costs split by configurable rules across namespaces.
- **Why right-size before committing?** Commitments lock in waste.
- **Spot interruption notice?** Two minutes; Karpenter and NTH drain on it.
- **What is split cost allocation data?** CUR pod-level cost for EKS by namespace and labels.
- **Budget action?** An automated IAM or SCP response when a budget threshold is hit.
- **Aurora I/O-Optimized when?** When I/O charges are roughly a quarter or more of the Aurora bill.
- **Graviton caveat?** Multi-arch images and native dependencies; test the JVM and Python wheels.

## Whiteboard prompts

Practise each on paper in ten minutes, talking as you draw.

1. **Platform landing zone.** Accounts and OUs, SCPs, Identity Center, logging and security accounts, shared services with CI and state, networking (TGW, egress), per-environment workload accounts for RFPL and RCPL.
2. **EKS cluster blueprint.** VPC with three tiers, private endpoint, system MNG plus Karpenter pools, add-ons, policy engine, ingress via ALB with WAF, ESO to Secrets Manager, observability stack, access entries, audit logs.
3. **Terraform repository layout and pipeline.** `modules/`, `stacks/`, `envs/<account>/<env>/`, CODEOWNERS, pre-commit, CI plan and policy, saved-plan apply, drift cron, state bucket design.
4. **Zero-downtime cluster upgrade timeline.** Week by week from reading release notes to prod node refresh.
5. **Admission policy rollout.** From audit to enforce with exemptions, dashboards and deadlines.
6. **DR for the lending core.** Mumbai primary, Hyderabad pilot light, Aurora Global Database, S3 CRR, Route 53 failover, runbook and drill evidence.
7. **Cost guardrail stack.** Tags at creation, Infracost, budgets, anomaly detection, quotas and NodePool limits, schedules, lifecycle, commitment review.

## Questions to ask them

Signals seniority and gives you information for Rounds 2 and 3.

- How many clusters and accounts today, which EKS versions, and how far behind is the furthest?
- Who applies Terraform today and from where; is there drift you know about?
- What was the last incident where infra was the blast radius, and what changed after it?
- What did the last audit (RBI, SOC 2) ask for that was hardest to produce?
- What does the DevOps team own that you wish it did not, and what does it not own that you wish it did?
- How is cost reported to product pods today?
- What would success look like in the first ninety days for this role?

## Day-before checklist

- Re-read the opinions sheet in [06-Stories-HiLabs-Mapping](06-Stories-HiLabs-Mapping.md) and say each one aloud.
- Rehearse Stories 1, 2 and 8 with numbers filled in; they cover all three Round 1 blocks.
- Run through the flawed module review once more, aloud, in under eight minutes.
- Check current facts: latest EKS version and standard-support dates, Terraform latest minor and what 1.10 to 1.12 added (native S3 locking, ephemeral resources, write-only arguments), Karpenter 1.x API names (`NodePool`, `EC2NodeClass`, `NodeClaim`), ValidatingAdmissionPolicy GA version (1.30), PSA since 1.25.
- Have a notepad with the three VPC tiers, the upgrade order of add-ons, and the debugging layer map, so you can draw quickly if screen-sharing.
- Prepare one sentence on why Rupeek: regulated fintech where infra matters, EKS-primary, a horizontal platform role with audit ownership, which is the senior-most shape of the work you already do.
- Set up the screen-share environment: a clean browser profile, a terminal with large font, no client names visible.
- Sleep. The debugging section of the round rewards a rested brain more than one more hour of reading.

## One-page cheat sheet

> **Terraform**: typed and validated inputs; secure defaults; no providers in modules; `for_each` over `count`; tag refs; one state per root; S3 versioned plus KMS plus native lock; directories per env; lock file committed; fmt, validate, tflint, checkov, Conftest on plan, `terraform test`, terratest for core; saved-plan apply via OIDC role; drift cron with `-detailed-exitcode`; `moved` and `import` blocks; secrets via RDS-managed passwords and ESO, ephemeral resources.
>
> **VPC**: three tiers per AZ; big node subnets; per-AZ NAT with documented EIPs; S3 and DynamoDB gateway endpoints, interface endpoints for ECR, STS, Secrets Manager, KMS, Logs, SSM; Flow Logs; prefix delegation; secondary CIDR with custom networking if squeezed; private EKS endpoint; subnet tags for the LB controller.
>
> **IAM**: no users or keys; Identity Center; SCPs for region and guardrails; boundaries on role creators; IRSA or Pod Identity per service; minimal node role; IMDSv2; Access Analyzer in CI; CloudTrail org trail with Object Lock.
>
> **Data**: Aurora PostgreSQL for the ledger, Multi-AZ, PITR plus AWS Backup vault lock, pgAudit, CMK, Blue/Green upgrades, RDS Proxy if needed; S3 with Block Public Access, TLS-only, SSE-KMS with bucket key, versioning, Object Lock for evidence, lifecycle, CRR within India; KMS keys per env and data class, `ViaService`, rotation, deletion alarms.
>
> **EKS ops**: system MNG plus Karpenter pools (general, stable, batch); PDBs and do-not-disrupt as defaults; disruption budgets by schedule; upgrade cadence one minor per four months; order control plane, CNI, kube-proxy, CoreDNS, CSI, Pod Identity agent, controllers, nodes; pinned AMI aliases and add-on versions; Kyverno plus PSA restricted plus VAP; default-deny network policies generated per namespace; security groups for pods on high-value flows; audit logs on.
>
> **Debugging map**: API server 429 (flowcontrol metrics, audit by userAgent); etcd 8 GB (Events, Jobs, Helm history); webhooks (failurePolicy, backends); node NotReady (conditions, kubelet and containerd journals, dmesg, disk, PLEG); OOM container vs node (137 and QoS eviction); CPU throttling (CFS periods); conntrack full (dmesg, sysctl, NodeLocal DNS); CNI no IP (subnet, ENI limits, WARM targets, prefix fragmentation); DNS (ndots, CoreDNS placement, UDP races); ALB 502 (readiness, preStop, deregistration delay, idle timeout).
>
> **Cost**: tags at creation; budgets and anomaly detection; Infracost gate; quotas, LimitRanges, NodePool limits; right-size, consolidate, spot, Graviton, Savings Plans; endpoints and per-AZ NAT; gp3; lifecycle on ECR, S3, logs, snapshots; non-prod to zero at night; show cost per team and per unit.
