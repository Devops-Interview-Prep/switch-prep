# Rupeek — Tech Lead DevOps · Round 1 Prep

> Preparation notes for Round 1 of the Rupeek Tech Lead DevOps loop: **Terraform / IaC module review, AWS + EKS deep dive, cost governance**. Written from the tech-lead perspective: what the interviewer is really testing, the standards to state and defend, failure modes to name unprompted, and model answers for every question type the round produces. The full JD is in [JD.md](JD.md).

---

## Files

| File | Covers |
|------|--------|
| [01-Round-Format.md](01-Round-Format.md) | Round structure, the tech-lead bar, how to structure answers, JD-to-notes map |
| [02-Terraform-IaC.md](02-Terraform-IaC.md) | Module design, state, workspaces vs directories, versions, testing, plan/apply gating, drift, secrets, TF vs Pulumi vs CDK, flawed-module live review exercise, 11 Q&As |
| [03-AWS-Architecture.md](03-AWS-Architecture.md) | Accounts and SCPs, VPC/CIDR for EKS, IAM and IRSA vs Pod Identity, RDS/Aurora, S3/KMS, multi-AZ vs multi-region, India data residency, 10 Q&As |
| [04-EKS-Operations-Debugging.md](04-EKS-Operations-Debugging.md) | Node groups and Karpenter, upgrade runbook, add-ons, admission control (Kyverno/PSA/VAP), network policies, layer-by-layer debugging map, 11 Q&As |
| [05-Cost-Governance.md](05-Cost-Governance.md) | Visibility, guardrails, optimisation levers in order of return, telling the cost story, 8 Q&As |
| [06-Stories-HiLabs-Mapping.md](06-Stories-HiLabs-Mapping.md) | Nine real experiences shaped as interview stories, opinions sheet, how to handle gaps |
| [07-Question-Bank-Checklist.md](07-Question-Bank-Checklist.md) | ~75 rapid-fire Qs, whiteboard prompts, questions to ask them, day-before checklist, one-page cheat sheet |
| [JD.md](JD.md) | The job description and interview process as shared by the recruiter |

## The round in one paragraph

Three blocks: (1) a screen-shared **review of a real Terraform module** probing boundaries, state, drift and review process; (2) **AWS + EKS architecture depth**: VPC, IAM, EKS operations, upgrades, admission controllers; (3) **cost governance**: guardrails you set up and optimisation you delivered. Every answer should carry three layers: the mechanism, the trade-off, and the standard you would enforce across a team.

## How to use

1. Read 01 once, then 02 to 05 as content with the Q&As at the end of each.
2. Fill in the numbers in 06 (cluster bill before/after Karpenter, spot share, number of root modules) and rehearse Stories 1, 2 and 8 aloud; they cover all three blocks.
3. Run the flawed-module review in 02 aloud in under eight minutes.
4. The night before: opinions sheet in 06, rapid-fire bank and checklist in 07.

## Interview loop (for context)

- **Round 1** — Terraform, IaC, Kubernetes & AWS deep dive (these notes)
- **Round 2** — Live scripting (Python/Go), a past production incident, end-to-end infra design for a new service
- **Round 3** — Security, compliance (RBI / SOC 2 / ISO 27001 / DPDP), infra vision, team and role fit
