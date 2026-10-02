# Rupeek Round 1 — Your stories: HiLabs experience mapped to the JD

> Nine real HiLabs experiences shaped as ninety-second interview stories, a one-breath opinions sheet, and how to handle gaps honestly.

---

Interviewers remember stories, not lists. Prepare each of these in the shape **situation, what you found, what you did, result, what you standardised**, about ninety seconds each, with one number in it. The purple boxes in earlier chapters point to the same material; this chapter collects it so you can rehearse in one sitting. Fill in the blanks with specifics only you know (numbers, dates, names of clusters) before the interview.

## Story 1: the Terraform platform library and ordered stacks

**Use for:** module boundaries, state, environment layout, "how do you create an environment".

The `devops-platform/terraform` library: vpc, eks, karpenter, argocd, alb-controller, IRSA, rds-postgres, mysql, elasticache, sqs, emr, solr, ecr, route53, kms, hybrid-vpc. New environment is three stacks applied in order: `01-network`, `02-eks-core`, `03-eks-platform`, state in an S3 bucket per account with native lock files. The one-command client environment (`./deploy --client X --env Y`) chaining Terraform, kubectl and ArgoCD, with the VA cluster as reference at about 44 minutes for 38 apps. The DevOps Launchpad wizard for per-service onboarding (namespace, ECR, values, ArgoCD app, Jenkins job, Route 53).

**What to emphasise:** why three stacks (different lifecycles and blast radius: network changes are rare and dangerous, platform add-ons change weekly), how cross-stack values flow, what the review gate looks like, and the debt you found and are fixing (a committed `terraform.tfstate` in one repo, `tfplan` binaries in another; fix is `.gitignore`, pre-commit, history purge, credential rotation). Also the Elevance side: Terraform Enterprise workspaces per environment in the client's Bitbucket, which lets you speak to the TFE workspace model from experience.

**Blanks to fill:** number of root modules and environments; how many engineers consume the modules; plan time of the largest stack; one concrete module you refactored and why.

## Story 2: Karpenter consolidation churn

**Use for:** node group strategy, consolidation trade-offs, debugging "restarting pods", cost versus reliability, setting platform defaults.

September 2026, dev cluster. Two services reported as "restarting frequently". Restart count zero on every pod, no OOM (peak RSS a fraction of the limit), no probe failures, no rollouts. Prometheus `kube_pod_info` showed 54 distinct pods for a 3-replica deployment in seven days; pod lifetimes 25 minutes to 12 hours. Loki query on Karpenter logs: 121 disruption decisions in 24 hours; every pod termination matched an `underutilized` delete or replace on its node within minutes; around 800 decisions and 812 node terminations per week on a 30-node pool, so a node lived about six hours. Cause: `WhenEmptyOrUnderutilized`, `consolidateAfter: 30m`, 25 percent disruption budget, plus bursty KEDA scale-to-zero, bitbucket runners and cron jobs every few minutes reshuffling the bin-packing. No PDBs in the namespace; data-service requested 5 GB and used up to 2 GB, which forced big nodes that looked cheap to replace.

**What you did:** a dedicated `hilabs-datarepo-stable` NodePool (label and taint, `WhenEmpty`, budget zero, `expireAfter: Never`, same EC2NodeClass), affinity and tolerations in six services' values, PDBs where the chart supported them, a recommendation to raise `consolidateAfter` and shrink the budget on the shared pool with an off-hours schedule, and a note that 800 node launches a week is itself cost (launch churn, image pulls).

**The tech-lead framing:** the platform shipped an aggressive default without shipping the protections; the fix is defaults in the shared chart (PDB on by default for replicas above one), a stable pool as a first-class offering, and consolidation budgets tied to business hours.

## Story 3: IRSA, IAM gaps and least privilege in practice

**Use for:** IAM, workload identity, "how do you debug permissions", regulated constraints.

IRSA roles for pods (S3, SQS, Secrets Manager) created by a Terraform module; SSO permission sets for DevOps; a separate Terraform role for changes. The CBH SFTP build blocked by missing `transfer:*`, `ec2:CreateVpcEndpoint` and `iam:PassRole` in the permission set, found only mid-build; the lesson you turned into a habit: `aws iam simulate-principal-policy` against the planned actions before starting, and raise the IT ticket first. Private EKS endpoints with SSO roles mapped via `aws-auth` and access entries.

**What to emphasise:** trust policy details (the OIDC provider, the `sub` condition), why node roles stay minimal, how you would move new clusters to Pod Identity, and how IAM changes flow through review.

## Story 4: the SNS topic policy that silently dropped alerts

**Use for:** debugging AWS event chains, IAM resource policies, "tell me about a non-obvious bug".

EventBridge to SNS email alerts for SFTP uploads never arrived. `TriggeredRules` showed matches, `FailedInvocations` showed failures; the SNS topic policy had an `aws:SourceArn` condition that EventBridge did not satisfy, so publishes were denied with no visible error. Fix: correct the condition, attach a DLQ to the EventBridge target so failures carry a message, confirm the subscription. Standard adopted: every EventBridge target gets a DLQ; alert on `FailedInvocations`.

## Story 5: shared NAT egress and the Maven Central 429s

**Use for:** VPC egress design, NAT as a shared fate, cost and reliability of egress, supply chain hygiene.

Every Java build across multiple pipelines failed at once with HTTP 429 from Maven Central because all builds egress through one NAT IP and the mirror (Nexus) was bypassed for new dependencies. Diagnosis across Jenkins, Dockerfiles and the Nexus proxy; fix in the Jenkinsfiles to route through the mirror and cache. The infrastructure lesson: a single shared egress IP is a single rate-limit and a single point of failure; per-AZ NAT plus pull-through caches (ECR pull-through, Nexus) plus VPC endpoints are the design answer, and dependency pinning plus an internal mirror is the supply chain answer.

## Story 6: ECR pull failures and ArgoCD-driven delivery

**Use for:** container runtime debugging, GitOps, how a deploy actually works.

`ImagePullBackOff` on a client's backend and frontend because the Helm values pointed at the wrong ECR repository; traced through the ApplicationSet, the values repo, the Jenkins job that rewrites the tag, and the ECR path. The broader platform: a shared umbrella chart published to Nexus, ApplicationSets discovering service folders, Jenkins or Bitbucket pipelines pushing to ECR with Inspector scanning on push and lifecycle policies.

## Story 7: Packer golden AMI and ephemeral build agents

**Use for:** immutable infrastructure, testing images, "a change that looked safe".

A Packer-built AMI for ephemeral Jenkins EC2 agents. First real job failed with "Host key verification failed" because `known_hosts` lacked `bitbucket.org`, and the ephemeral agent shared a label with static agents so jobs landed on it unexpectedly. Fixes: bake `ssh-keyscan` into the image, a distinct label, and a real job as part of the image test. Lesson: a golden image is not tested until a real workload has run on it; the same applies to a new EKS AMI alias.

## Story 8: cost levers and the OKR behind them

**Use for:** cost governance, business framing.

Karpenter consolidation and spot pools; KEDA scale-to-zero for GPU; Azure auto-shutdown runbook for a SQL Managed Instance (first version silently no-op because the SDK returned an empty state field, fixed by calling the REST API, which is also a story about verifying automation); S3 lifecycle (IA at 60 days, expire at 90 for CI artifacts); ECR lifecycle; Kubecost on AKS; the margin OKR driving one-command environments. Fill in the numbers.

## Story 9: the client-cloud (Elevance) constraints

**Use for:** regulated-industry constraints, change management, working with Infosec, evidence.

Shipping into a customer's multi-tenant EKS: CyberArk heightened accounts, SAML then role switch, OIDC `kubectl`, Terraform Enterprise workspaces, Quay with Wiz scanning, Splunk, Datadog, ServiceNow tickets for every non-Terraform change, ArgoCD per environment. This is close to how a bank partner or an RBI auditor will expect Rupeek to operate: every change ticketed, every access attributable, scanning before deploy. Use it to show you are comfortable with process-heavy environments without becoming a bottleneck.

## Opinions sheet (say these in one breath)

- Directories per environment, not workspaces; composition modules for DRY; Terragrunt only past about thirty stacks.
- Terraform or OpenTofu for the platform because the plan is the control; Pulumi for developer-led app infra; CDK for single-team AWS-native products.
- Native S3 lock files on Terraform 1.10+; one state per root module; state is a secret.
- Apply only saved plans from CI via OIDC roles; no laptop applies; break-glass pages.
- Managed node group for the platform pool, Karpenter for workloads, PDBs and a stable pool as defaults, consolidation budgets by schedule.
- One minor version every four months, never more than one behind; add-ons pinned; AMI aliases pinned.
- Kyverno plus PSA restricted, VAP for invariants, audit before enforce.
- Default-deny network policy generated per namespace; security groups for pods on the few high-value flows.
- Pod Identity for apps on new clusters, IRSA for add-ons and existing clusters.
- Multi-AZ always; pilot light in Hyderabad for the lending core; DR drills with evidence.
- Tagging at creation, Infracost on PRs, budgets and anomaly detection, right-size before you commit.
- Cost is a reliability property; untagged spend is unowned infrastructure.

## Gaps to be honest about

Decide in advance how you will answer if asked about things you have used less: Aurora Global Database or Blue/Green deployments at scale, Gatekeeper and Rego, Cilium, terratest in anger, Spacelift or Atlantis specifically, SOC 2 evidence collection (Round 3, but it may surface). The right shape is "I have not run X in production; here is the closest thing I have done, and here is how I would evaluate X in the first month." Senior interviewers trust that more than a bluff, and bluffs are easy to detect in a deep-dive round.
