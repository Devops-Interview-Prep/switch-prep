# 🎤 CI/CD Integration
**6 Slides · GitHub Actions, OIDC, Atlantis, Terraform Cloud**

---

# 🔴 Slide 1 · Scenario: GitHub Actions + Terraform Pipeline

**🏗️ Setup**
> *You need a complete CI/CD pipeline for Terraform — format check, security scan, plan on PR, apply on merge to main — with no long-lived AWS credentials.*

**❓ The Question**
Walk me through a production-grade GitHub Actions Terraform pipeline.

**🔍 Diagnosis**
1. Separate jobs for validate, security scan, plan, and apply — never combine them
2. Use OIDC for AWS auth — no static access keys stored in GitHub Secrets
3. Use separate IAM roles for plan (read-only) and apply (write)
4. Upload plan artifact from plan job; download and apply in the apply job
5. Apply job only runs on push to main — never on PRs

**✅ Fix**
```yaml
on:
  pull_request:
    branches: [main]
    paths: ['infrastructure/**']   # ← only trigger on TF file changes
  push:
    branches: [main]
    paths: ['infrastructure/**']

jobs:
  validate:
    steps:
      - run: terraform fmt -check -recursive    # ← fails if formatting is wrong
      - run: terraform init -backend=false && terraform validate

  security-scan:
    steps:
      - uses: aquasecurity/tfsec-action@v1.0.0
      - uses: bridgecrewio/checkov-action@v12

  plan:
    needs: [validate, security-scan]            # ← plan only runs if both pass
    permissions:
      id-token: write                           # ← required for OIDC token exchange
      pull-requests: write                      # ← required to comment on PRs
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.TF_PLAN_ROLE_ARN }}  # ← read-only role
      - run: terraform plan -out=plan.tfplan -no-color 2>&1 | tee plan.txt
      - uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          retention-days: 1                     # ← stale plans are dangerous

  apply:
    needs: plan
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    environment:
      name: production                          # ← GitHub environment approval gate
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.TF_APPLY_ROLE_ARN }}  # ← write role, main only
      - uses: actions/download-artifact@v4
        with: { name: terraform-plan }
      - run: terraform apply -auto-approve plan.tfplan   # ← applies the exact saved plan
```

**🛡️ Prevention**
- Set `retention-days: 1` on plan artifacts — stale plans are dangerous
- Require GitHub environment approval on the `production` environment
- Use branch protection to prevent direct pushes to main

> ⚠️ **Never:** Run `terraform apply` directly (not from a saved plan) in CI — what you reviewed may not match what gets applied if state changed between jobs

---

# 🔴 Slide 2 · Scenario: Atlantis — Pull Request Automation

**🏗️ Setup**
> *Your team wants plan output directly in PRs without maintaining a full GitHub Actions pipeline. Terraform changes should require PR approval before applying.*

**❓ The Question**
How does Atlantis work and how do you configure it?

**🔍 Diagnosis**
1. Atlantis runs as a self-hosted server with access to your Git provider webhook
2. On PR open, Atlantis auto-comments with `terraform plan` output
3. Apply is triggered by a PR comment — not a merge
4. Workspace is locked during apply and unlocked when complete

**✅ Fix**
```yaml
# atlantis.yaml — project config at repo root
version: 3
projects:
  - name: prod-vpc
    dir: infrastructure/prod/vpc
    workspace: prod
    autoplan:
      enabled: true
      when_modified: ["*.tf", "*.tfvars", "../modules/**"]  # ← auto-plan on these changes
    apply_requirements: [approved, mergeable]               # ← needs PR approval before apply

  - name: staging-vpc
    dir: infrastructure/staging/vpc
    workspace: staging
    autoplan:
      when_modified: ["*.tf", "../modules/**"]
    apply_requirements: [approved]
```

**Atlantis PR workflow:**
1. Developer opens PR → Atlantis auto-comments with plan output
2. Reviewer reads plan, approves PR
3. Developer comments `atlantis apply -p prod-vpc` on the PR
4. Atlantis applies, locks workspace; unlocks and merges when complete

| | Atlantis | GitHub Actions |
|--|----------|---------------|
| **Plan trigger** | Auto on PR | Workflow yaml |
| **Apply trigger** | PR comment | Merge to main |
| **State locking** | Per-workspace, built-in | Via DynamoDB |
| **Cost** | Free (infra cost only) | Free tier + per-minute |

**🛡️ Prevention**
- Always set `apply_requirements: [approved, mergeable]` for prod workspaces
- Run Atlantis on an instance with a restrictive security group — it holds broad IAM permissions
- Use Atlantis server-side repo allowlist to restrict which repos can trigger runs

> ⚠️ **Never:** Set `apply_requirements: []` in prod — without approval requirements, any developer can apply to prod by commenting on their own PR

---

# 🔴 Slide 3 · Scenario: Terraform Cloud Workflow

**🏗️ Setup**
> *Your team wants a managed solution — no self-hosted Atlantis, no S3 backend to maintain. You're evaluating Terraform Cloud.*

**❓ The Question**
How does the Terraform Cloud workflow differ from self-managed, and when would you choose it?

**✅ Fix**
```hcl
# terraform.tf — use TFC as both backend and CI orchestrator
terraform {
  cloud {
    organization = "myorg"
    workspaces {
      name = "prod-vpc"
    }
  }
}
```

**TFC Run Types:**

| Run Type | Trigger | What it does |
|--|--|--|
| **Speculative plan** | On PR | Read-only plan; comments result on PR |
| **Plan + Apply** | On merge to main | Full apply with human approval gate |
| **Destroy run** | Manual (API or UI) | Destroys all resources in workspace |
| **Refresh-only** | Scheduled or manual | Detects drift without applying |

**TFC vs Self-managed backend:**

| | Terraform Cloud | S3 + DynamoDB |
|--|----------------|---------------|
| **State storage** | Managed, encrypted | Self-managed |
| **Locking** | Managed | DynamoDB |
| **Policy as code** | Sentinel (paid tier) | tfsec/checkov |
| **Audit logs** | Native | CloudTrail |
| **Cost** | Free up to 5 users | Storage costs only |

**🛡️ Prevention**
- Enable workspace-level run approval for all prod TFC workspaces
- Use TFC variable sets to manage provider credentials centrally across workspaces

> ⚠️ **Never:** Choose TFC for air-gapped environments or organizations that cannot allow state to leave their network perimeter

---

# 🎤 Slide 4 · Follow-up Q&A

---

### Q: Why use two different IAM roles for plan and apply in CI?
- Principle of least privilege: the plan role needs only read permissions (`Describe*`, `List*`, `Get*`)
- The apply role needs write permissions (`Create*`, `Update*`, `Delete*`)
- In PRs, only the plan role is used — a compromised PR cannot make infrastructure changes
- The apply role is used only on `main` branch after approval

> 💬 **Say:** "If a malicious PR slips through, the worst it can do with the plan role is read your infrastructure description. It cannot change anything."

---

### Q: Why do plan artifacts expire and why shouldn't you reuse them?
- A plan file is tied to the state version at the moment of planning
- If state changes between plan and apply (another PR merged, manual change), the plan is stale
- Applying a stale plan can fail with a state serial mismatch OR succeed but produce unexpected results
- Keep plan artifacts for max 1 day; always re-plan on the day of apply

> 💬 **Say:** "A plan is a snapshot of intent at a moment in time. Applying yesterday's plan to today's state is like executing a surgery plan on the wrong patient — the target changed."

---

### Q: How do you handle Terraform in a monorepo where changes in one module shouldn't trigger plans for unrelated modules?
- Use changed-file detection: `git diff --name-only origin/main | grep '\.tf$'` to find modified files, extract directories, and only plan those
- Atlantis does this automatically via `when_modified` patterns in `atlantis.yaml`
- For Terragrunt: `terragrunt run-all plan --terragrunt-include-dir $(changed-dirs)`
- Never run plan for all modules on every commit — at scale this produces a 45-minute pipeline

> 💬 **Say:** "At scale, running all plans on every commit is how you get developers who stop waiting for CI feedback and start making unreviewed changes."

---
