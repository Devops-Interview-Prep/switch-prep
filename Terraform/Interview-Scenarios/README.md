# Terraform Interview Scenarios

Senior-level Terraform scenarios that test both breadth and depth. Each file covers a theme with real-world situations, expected diagnosis steps, and correct answers.

## Files

| File | Theme |
|------|-------|
| [01-State-Management.md](01-State-Management.md) | State corruption, drift, imports, locks |
| [02-Architecture-Patterns.md](02-Architecture-Patterns.md) | Multi-account, DRY, monorepo patterns |
| [03-Advanced-HCL.md](03-Advanced-HCL.md) | Complex expressions, edge cases |
| [04-CI-CD-Integration.md](04-CI-CD-Integration.md) | Pipelines, Atlantis, Terraform Cloud |
| [05-Troubleshooting.md](05-Troubleshooting.md) | Real error scenarios and fixes |
| [06-Security-Secrets.md](06-Security-Secrets.md) | Credentials, secrets, least privilege |
| [07-Real-Platform-Code-Review.md](07-Real-Platform-Code-Review.md) | 12 scenarios lifted from the real platform repo in [../Real-World/](../Real-World/): leaked password, committed state, wrong IAM policy, provider-in-module, AZ removal, AMI drift, lockout, NAT topology |
| [08-Design-and-Operations-Drills.md](08-Design-and-Operations-Drills.md) | 14 tech-lead drills: DRY roots, state splits, IRSA to Pod Identity, provider majors, drift, OPA on plans, blue/green clusters, state-bucket loss, multi-account, DR region, live-coding prompts |

## How to Use

Work through each scenario like an interview. Cover: (1) What's the root cause? (2) What would you do to diagnose? (3) What's the fix? (4) How do you prevent recurrence?
