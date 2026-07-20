# Kubernetes Interview Scenarios

Senior-level Kubernetes scenarios that test both breadth and depth. Each file covers a theme with real-world situations, expected diagnosis steps, and correct answers — mirrors the format of [Terraform/Interview-Scenarios](../../Terraform/Interview-Scenarios/README.md).

## Files

| File | Theme |
|------|-------|
| [01-Scheduling-Capacity.md](01-Scheduling-Capacity.md) | Pending pods, quotas, PDB deadlocks, HPA/VPA/CA conflicts |
| [02-Networking-Ingress.md](02-Networking-Ingress.md) | Service/Ingress/NetworkPolicy routing and enforcement failures |
| [03-Storage-StatefulSet.md](03-Storage-StatefulSet.md) | PVC/PV AZ mismatches, StatefulSet data gotchas, reclaim policy |
| [04-Security-RBAC.md](04-Security-RBAC.md) | Admission webhooks, RBAC over-permissioning, Pod Security Admission, OPA Gatekeeper |
| [05-Rollouts-GitOps.md](05-Rollouts-GitOps.md) | ConfigMap reload, Helm/Kustomize rollout surprises, CRD/operator issues |
| [06-Cluster-Upgrades-Troubleshooting.md](06-Cluster-Upgrades-Troubleshooting.md) | Node drain stalls, node NotReady timing, API deprecations, incident triage |

## How to Use

Work through each scenario like an interview. Cover: (1) What's the root cause? (2) What would you do to diagnose? (3) What's the fix? (4) How do you prevent recurrence?

Each scenario cross-references the relevant deep-dive doc in [../Components/](../Components/) for the full mechanism behind the fix.
