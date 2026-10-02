# Terraform in the Real World — a production platform repo, annotated

> A sanitised copy of a real internal platform repository (`devops-platform/terraform`) that builds client environments on AWS: VPC, EKS, Karpenter, ArgoCD, and per-application RDS/S3/SQS/ElastiCache. Account IDs, client and product names, domains, IPs, SSO role names and resource IDs have been replaced with placeholders; state, plan and lock files were dropped. The code is otherwise as it runs. Use it to practise the "review a real Terraform module" interview round: read the code, then read the notes that explain **why each block is there**, **what is good**, and **what a tech lead would change**.

---

## Files

| File | What it covers |
|------|----------------|
| [devops-platform/](devops-platform/) | The sanitised code: `bootstrap/`, `modules/`, `stacks/`, `environments/` |
| [01-Repository-Layout-and-Flow.md](01-Repository-Layout-and-Flow.md) | The three layers (modules, stacks, environments), the 01 → 02 → 03 apply order, how state and providers are wired, where the Launchpad UI fits |
| [02-Block-by-Block-Walkthrough.md](02-Block-by-Block-Walkthrough.md) | Every stack and module: what each resource block does, why it exists, the gotchas it protects against |
| [03-Review-Findings.md](03-Review-Findings.md) | An honest tech-lead review of this code: 30+ findings with severity, the fix, and what you would say in the interview |
| [../Best-Practices.md](../Best-Practices.md) | Terraform best practices, each tied to where this repo follows or breaks them |
| [../What-To-Use-Terraform-For.md](../What-To-Use-Terraform-For.md) | What Terraform *can* do vs what you *should* use it for, given Helm, ArgoCD, Ansible, Packer, Crossplane, CloudFormation, Pulumi and friends |
| [../Interview-Scenarios/07-Real-Platform-Code-Review.md](../Interview-Scenarios/07-Real-Platform-Code-Review.md) | Interview scenarios lifted straight from this codebase |
| [../Interview-Scenarios/08-Design-and-Operations-Drills.md](../Interview-Scenarios/08-Design-and-Operations-Drills.md) | Design and operations drills: migrations, upgrades, policy, DR, live-coding prompts |

## How to practise with it

1. Open `devops-platform/stacks/new-environment/02-eks-core/main.tf` cold and narrate a review out loud for eight minutes, using the scan order from [interviews/rupeek/round1/02-Terraform-IaC.md](../../interviews/rupeek/round1/02-Terraform-IaC.md). Then compare against [03-Review-Findings.md](03-Review-Findings.md).
2. Repeat with `modules/eks/karpenter/` (Helm plus `kubectl_manifest` from templates) and `stacks/application-stack/` (feature-flag module with `count`).
3. Draw the apply order and state dependencies from memory, then check [01-Repository-Layout-and-Flow.md](01-Repository-Layout-and-Flow.md).
4. Work the scenarios in 07 and 08 as if asked live: root cause, diagnosis, fix, prevention.

## Placeholders used

| Placeholder | Stands for |
|---|---|
| `123456789012` | the AWS account ID |
| `example`, `Example` | the company name |
| `clienta`, `clientb`, `clientc`, `clientd` | client names |
| `proda`, `prodb`, `prodc`, `prodd` | product names |
| `203.0.113.x` | office / VPN public IPs (TEST-NET-3) |
| `10.0.0.10`, `10.0.0.11` | on-prem resolver / host IPs |
| `AWSReservedSSO_PlatformAdmin_...` | Identity Center permission-set roles |
| `vpc-…`, `subnet-…` (17 hex) | real resource IDs, replaced with hashes |
| `example-tf-state-123456789012-us-east-1` | the state bucket |
