# Rupeek Round 1 — Cost governance

> Visibility, guardrails that stop silent growth, optimisation levers in order of return, and how to tell a cost story with numbers.

---

The JD phrases it as "past experience in setting up cost guardrails and optimising cost". Two different things: **guardrails** stop the bill growing silently; **optimisation** reduces it deliberately. A tech lead is judged on the first, because anyone can delete idle instances once. Rupeek is profitable since 2024 and investor-funded, so the finance team watches cloud cost per loan disbursed; expect a question about **showing** cost per team or product, not just cutting it.

## Visibility first

- **Tagging strategy**: a short mandatory set (`environment`, `service`, `team`/`owner`, `cost-center`, `managed-by`), enforced at creation: AWS provider `default_tags`, a Conftest policy on the plan rejecting untagged resources, AWS Organizations **tag policies**, and a weekly report of untagged spend from the Cost and Usage Report (CUR). Kubernetes labels map to the same keys so pod-level cost joins account-level cost.
- **Cost allocation tags** activated in Billing, **cost categories** to group accounts and tags into business units (RFPL vs RCPL, product pods, shared platform).
- **CUR into S3 plus Athena/QuickSight** (or a FinOps tool) for anything beyond what Cost Explorer answers; CUR is also the data source for anomaly investigations and for chargeback.
- **Kubernetes cost**: Kubecost / OpenCost, or AWS **split cost allocation data** for EKS in the CUR (pod-level CPU and memory cost by namespace and label). Show each team their namespace cost monthly; shared platform cost is allocated by a published formula.
- **Dashboards that matter**: cost by service by day, cost per environment, cost per unit of business (per thousand API calls, per loan), top movers week over week, waste report (idle, unattached, untagged).

## Guardrails

- **AWS Budgets** per account and per team with alerts at 50/80/100 percent of forecast, to a channel and to the team owner, plus a **budget action** in sandboxes that attaches a deny policy when exceeded.
- **Cost Anomaly Detection** on services and on cost categories, alerting within hours of a spike (the classic: a logging change multiplies CloudWatch ingestion, or a loop hammering NAT).
- **Service Control Policies**: deny expensive instance families and GPU types outside approved accounts, deny regions, deny creating resources without required tags where the service supports it (`aws:RequestTag` conditions on `RunInstances`, `CreateVolume`, `CreateBucket`).
- **Infracost on every Terraform PR**: show the monthly delta; require an extra approval above a threshold (say, 500 USD per month) and block above a hard cap without a tag like `cost-approved`.
- **Kubernetes guardrails**: ResourceQuotas and LimitRanges per namespace; Kyverno requiring requests and limits and capping the ratio of limit to request; a policy denying GPU requests outside the ML namespaces; `karpenter` NodePool `limits` (total CPU and memory) so a runaway HPA cannot provision a hundred nodes; HPA `maxReplicas` reviewed.
- **Non-prod schedules**: scale non-prod to zero outside working hours (KEDA cron scaler, a `kube-downscaler`, Karpenter consolidation takes the nodes away), RDS stop on schedule (seven-day auto-restart caveat), Aurora Serverless v2 with pause for dev. Expect 40 to 60 percent on non-prod compute.
- **Lifecycle policies**: ECR (keep last N tags, expire untagged), S3 (IA/Glacier tiers, expire noncurrent versions, abort multipart), CloudWatch log groups with retention set by Terraform default (never "Never expire"), EBS snapshot retention via Data Lifecycle Manager, orphaned EBS volumes and unattached EIPs swept weekly.
- **Commitment governance**: a quarterly review of Savings Plans coverage and utilisation; a rule that new steady-state workloads are covered after 60 days of data.

## Optimisation levers, in order of return

1. **Right-size requests** from real usage (VPA in recommendation mode, Goldilocks, Kubecost). Over-requesting is the most common Kubernetes waste: pods request 5 GB and use 1 GB, so nodes look full while idle. Target 60 to 80 percent utilisation of requests.
2. **Karpenter consolidation and instance diversity**: wide instance lists, let it pick the cheapest fit, consolidation on with the guardrails from [04-EKS-Operations-Debugging](04-EKS-Operations-Debugging.md). This alone typically yields 20 to 30 percent over fixed ASGs.
3. **Spot** for stateless and batch (60 to 90 percent discount), with diversification and PDBs. **Graviton** for anything with multi-arch images (20 to 40 percent better price-performance): JVM, Go, Python services almost always work; check native dependencies.
4. **Savings Plans** for the measured baseline (compute SP for EC2 flexibility), RDS/ElastiCache/OpenSearch reserved instances. Typical 30 to 40 percent on the committed portion.
5. **Data transfer**: VPC endpoints for S3/ECR/CloudWatch (NAT data processing is often a top-five line item), per-AZ NAT so traffic stays local, topology-aware routing for chatty east-west traffic, CloudFront in front of S3 for customer downloads, compress logs and metrics in transit.
6. **Storage**: gp2 to gp3 (20 percent cheaper, provisioned IOPS decoupled), EBS size right-sizing, S3 Intelligent-Tiering for unknown access patterns, delete old snapshots, EFS IA.
7. **Databases**: Graviton instance classes, Aurora I/O-Optimized when I/O exceeds roughly a quarter of the bill, Serverless v2 in non-prod, stop idle non-prod, consolidate tiny instances, read replicas only where read traffic justifies.
8. **Observability cost**: CloudWatch Logs ingestion and Datadog/New Relic custom metrics are routine runaway items; set retention, sample debug logs, drop high-cardinality labels in Prometheus (`metric_relabel_configs`), tier logs to S3 with Loki or Athena.
9. **Idle and zombie resources**: unattached volumes and EIPs, idle load balancers, old AMIs and snapshots, forgotten test clusters, NAT gateways in VPCs nobody uses; Trusted Advisor and Compute Optimizer surface most of this.
10. **Architecture**: the big wins are design-time: fewer NAT paths, fewer cross-AZ hops, fewer always-on components (queues plus scale-to-zero workers instead of polling fleets).

## Telling the story

Interviewers want a before/after with numbers and a **guardrail that kept it from regressing**. Structure: baseline (monthly bill, top five services), what you found (idle nodes, over-requested pods, NAT data, no Savings Plans), what you did in what order, the result (percent and absolute), and what you installed so it stays fixed (Infracost gate, budgets, Kyverno quotas, consolidation defaults). Then the trade-off you accepted or reversed: aggressive consolidation saved money but caused churn, so you paid some back with a stable pool.

> **Your story:** HiLabs levers you have actually used: Karpenter consolidation and spot pools across the EKS clusters; KEDA scale-to-zero for GPU work (Contracts AI); auto-shutdown schedules on Azure (the SQL Managed Instance stop runbook under a managed identity, after the first version silently did nothing); S3 lifecycle rules (Standard-IA at 60 days, expire at 90 for CI artifacts); ECR lifecycle policies; Kubecost on AKS; the "Cloud Cost Optimization Strategy" and client cost pages; the company OKR of 75%+ gross margin and under 90k dollars implementation cost per million ARR that drove one-command environments and the Launchpad. And the Karpenter churn incident as the counter-example: consolidation at 30 minutes with a 25 percent budget caused around 800 node replacements a week and user-visible evictions. If you have numbers (cluster bill before and after Karpenter, spot share, non-prod shutdown savings), write them in the margin now and use them.

> **Have an opinion:** "Cost is a reliability and security property, not a finance chore. Untagged spend is unowned infrastructure, and unowned infrastructure is where incidents and audit findings live. So the guardrail is tagging at creation, the lever is right-sizing plus consolidation, and the rule is every optimisation ships with the control that keeps it true."

## Interview questions and model answers

### Q1: What cost guardrails have you set up?

Mandatory tags via provider default_tags and a plan policy; budgets with alerts per account and team; Cost Anomaly Detection; Infracost on PRs with an approval threshold; ResourceQuotas and Kyverno rules for requests and limits; Karpenter NodePool limits; non-prod scale-to-zero schedules; lifecycle policies on ECR, S3, CloudWatch logs and snapshots; quarterly Savings Plans review. Each one exists because a specific surprise bill happened.

---

### Q2: Describe a cost optimisation you led, with numbers.

Use the HiLabs story: baseline, levers in order (right-size requests, Karpenter with consolidation and spot, Graviton where images allowed, gp3, endpoints for NAT, S3 and ECR lifecycle, non-prod scheduling, Savings Plans on the remainder), the result as a percent of the cluster bill, and the regression guardrails. Then the churn incident as the lesson about pushing consolidation too hard.

---

### Q3: How do you show each team what they cost?

Namespace and label mapping to the tag set; Kubecost or EKS split cost allocation in the CUR for pod-level cost; cost categories to roll platform cost up by a published formula; a monthly report to each pod lead and a dashboard; unit metrics such as cost per thousand requests so growth is separated from waste.

---

### Q4: A team's HPA scaled to 200 pods overnight and the bill spiked. What should have stopped it?

Layers: HPA `maxReplicas` reviewed in code review, namespace ResourceQuota, Karpenter NodePool CPU and memory limits, Cost Anomaly Detection alert within hours, and an SLO-based alert on request rate that would have shown the traffic (or the metric bug) first. Post-incident: add the missing layer and a Kyverno rule requiring `maxReplicas`.

---

### Q5: Spot for production?

Yes for stateless replicas and batch with diversification, PDBs, graceful termination handling and a minimum on-demand floor via NodePool weights or a separate on-demand pool. No for singletons, stateful sets, the policy engine, or anything whose SLO cannot absorb a 2-minute interruption. Monitor interruption rate per instance type and rebalance the list.

---

### Q6: Where does NAT gateway cost come from and how do you cut it?

Hourly per gateway plus per GB processed. Pulling images from ECR, writing logs to CloudWatch, S3 traffic and STS calls all go through NAT without endpoints. Gateway endpoints for S3 and DynamoDB are free; interface endpoints for ECR, Logs, STS, Secrets Manager, KMS pay for themselves quickly. Per-AZ NAT avoids cross-AZ charges. Watch `BytesOutToDestination` per NAT and find the top talkers via Flow Logs.

---

### Q7: How do you decide how much Savings Plan to buy?

Measure 60 to 90 days of on-demand steady state after optimisation (never commit before right-sizing), buy compute Savings Plans for roughly 70 to 80 percent of the floor so growth and spot cover the rest, one-year no-upfront or partial-upfront depending on finance, stagger purchases quarterly so expiry is not a cliff, and track coverage and utilisation monthly.

---

### Q8: What is the cost trade-off of running three AZs?

Cross-AZ data transfer per GB both directions, three NAT gateways, replicas times three. Worth it for prod because an AZ event with two AZs leaves 50 percent capacity and with three leaves 67 percent, and because RDS Multi-AZ and EKS control plane already assume it. Mitigate with topology-aware routing, AZ-local caches and compressing chatty traffic. Non-prod can be two AZs.

---
