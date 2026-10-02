# Rupeek Round 1 — The round, the bar, and how to answer

> What Round 1 covers, what 'Tech Lead' changes about the bar, and how to structure every answer (mechanism, trade-off, standard).

---

## What Round 1 is

The JD names three blocks for Round 1: **review a real Terraform module** (module boundaries, state, drift, review process), **AWS and EKS architecture depth** (VPC, IAM, EKS operations, upgrades, admission controllers), and **cost governance** (guardrails you have set up, optimisation you have delivered). Expect 60 to 90 minutes with one or two senior people, probably the current senior-most DevOps or an SDE III plus the hiring manager. The Terraform review is usually screen-shared: they open a module from their own repo (or a deliberately flawed sample) and ask you to talk through it as if it were a pull request.

## What "Tech Lead" changes about the bar

For a mid-level role the question is "do you know X". For this role the question is "**would you set the standard for X and could you defend it to an SDE III**". Every answer should carry three layers:

1. **The mechanism.** How it actually works (what the API does, what the state file contains, what the kubelet does).
2. **The trade-off.** Why you would choose it and when you would not. "It depends" is fine only if you immediately say what it depends on.
3. **The standard.** How you would make a team of five do it the same way without you reviewing every PR: a module convention, a CI check, a policy, a template.

The interviewer is also silently scoring: do you reach for a real example unprompted, do you say "I don't know, here is how I'd find out" cleanly, and do you push back when they propose something risky.

> **What the interviewer is really testing:** Rupeek is a regulated fintech (RBI, DPDP, SOC 2, ISO 27001). Even in a technical round, mention audit trails, least privilege, data residency (ap-south-1 / Mumbai, Hyderabad as secondary) and evidence collection where natural. It signals that you have thought about their world, not just about Kubernetes.

## How to structure an answer

- **Lead with the answer**, then the reasoning. "I would use directory-per-environment, not workspaces. Three reasons."
- **Name the failure mode.** Senior engineers are recognised by the failure they are avoiding, not by the feature they are using.
- **Quantify when you can.** Node count, savings percentage, minutes of downtime, number of modules. Rough numbers are fine; "about 800 node replacements a week" is better than "a lot of churn".
- **Close with the standard.** "and we enforced that with a tflint rule / a Kyverno policy / a PR template."
- **When reviewing code live**: narrate your scan order out loud (inputs, outputs, resources, lifecycle, IAM, tags, versions) so they see a method, not luck.

## Topics the JD puts in Round 1, mapped to chapters

| **JD line** | **What they will probe** | **Chapter** |
|---|---|---|
| Review a real Terraform module; module boundaries, state, drift, review process | Module design, remote state, locking, workspaces vs directories, drift detection, PR plan/apply gating, versioning, testing tools, TF vs Pulumi vs CDK | [02-Terraform-IaC](02-Terraform-IaC.md) |
| Deep AWS: VPC design, IAM, EKS, RDS/Aurora, S3, KMS, cost architecture, multi-AZ / multi-region | CIDR planning for EKS, subnet tiering, NAT, endpoints, IAM least privilege, IRSA vs Pod Identity, Aurora failover, S3 security posture, KMS key design, DR trade-offs | [03-AWS-Architecture](03-AWS-Architecture.md) |
| EKS operations: node group strategy, upgrades, addons lifecycle, admission controllers, network policies, PSA | Managed node groups vs Karpenter, upgrade runbook, addon ordering, Kyverno/Gatekeeper/VAP, Pod Security Admission rollout, default-deny network policy | [04-EKS-Operations-Debugging](04-EKS-Operations-Debugging.md) |
| Debugging at layers others can't: kernel/OS, container runtime, CNI, etcd, control plane | IP exhaustion, conntrack, OOM vs eviction, containerd, etcd size and latency, API server throttling, node NotReady | [04-EKS-Operations-Debugging](04-EKS-Operations-Debugging.md) |
| Cost governance: guardrails, past optimisation | Tagging enforcement, budgets and anomaly detection, Karpenter consolidation, spot, Graviton, Savings Plans, NAT and cross-AZ data, storage lifecycle, showback | [05-Cost-Governance](05-Cost-Governance.md) |

[06-Stories-HiLabs-Mapping](06-Stories-HiLabs-Mapping.md) maps your HiLabs experience onto these so you have a ready story for each. [07-Question-Bank-Checklist](07-Question-Bank-Checklist.md) is the question bank in rapid-fire form plus whiteboard prompts and a day-before checklist.
