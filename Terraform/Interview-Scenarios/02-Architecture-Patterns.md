# 🎤 Terraform Architecture Patterns
**7 Slides · Multi-Account, Monorepo, Modules, Environments, Scale**

---

# 🔴 Slide 1 · Scenario: Multi-Account AWS Architecture

**🏗️ Setup**
> *You need to design Terraform architecture for 3 AWS accounts — shared-services, staging, and prod — with a shared networking layer.*

**❓ The Question**
Design the Terraform architecture for this multi-account setup.

**🔍 Diagnosis**
1. Separate account directories under a single `accounts/` tree
2. Shared reusable modules live outside account directories
3. Cross-account providers use `assume_role` with account-specific IAM roles
4. Cross-account outputs shared via `terraform_remote_state` data source

**✅ Fix**
```
infrastructure/
├── accounts/
│   ├── shared-services/networking/   # Transit Gateway, shared VPC
│   ├── staging/  vpc/ eks/ rds/
│   └── prod/     vpc/ eks/ rds/
├── modules/  vpc/  eks/  rds/        # Reusable modules
└── terragrunt.hcl                    # Root: DRY backend + provider config
```

```hcl
# Cross-account provider — one alias per account
provider "aws" {
  alias = "prod"
  assume_role {
    role_arn = "arn:aws:iam::PROD_ACCOUNT:role/TerraformRole"
  }
}

# Reference shared-services outputs across accounts
data "terraform_remote_state" "shared_networking" {
  backend = "s3"
  config  = { bucket = "my-tf-state-shared"
               key    = "shared-services/networking/terraform.tfstate" }
}
```

**🛡️ Prevention**
- Create a dedicated `TerraformRole` in each account with least-privilege permissions
- Never use root account or personal credentials for CI runs
- State buckets should live in the shared-services account, not in prod

> ⚠️ **Never:** Use a single provider with a single IAM role across all accounts — account isolation is the entire point

---

# 🔴 Slide 2 · Scenario: Monorepo vs Polyrepo

**🏗️ Setup**
> *Your org is debating whether all Terraform code should live in one repository or be split across multiple repos by team or service.*

**❓ The Question**
What are the trade-offs between monorepo and polyrepo for Terraform?

**🔍 Diagnosis**
1. Consider team size and coupling between infrastructure components
2. Evaluate how code is shared between teams
3. Consider CI/CD complexity and access control requirements

**✅ Fix**

| | Monorepo | Polyrepo |
|--|----------|----------|
| **Code sharing** | Local paths (`../modules/vpc`) | Git tags (`git::https://...`) |
| **CI/CD** | Detect changed dirs, targeted plans | Per-repo pipelines |
| **Access control** | CODEOWNERS + branch protection | Per-repo IAM |
| **Best for** | Small-medium teams, tight coupling | Large orgs, team autonomy |

```yaml
# Monorepo CI: only plan directories that changed
- name: Detect changed Terraform dirs
  run: |
    changed=$(git diff --name-only origin/main HEAD \
      | grep '\.tf$' | xargs -I{} dirname {} | sort -u)
    for dir in $changed; do
      (cd $dir && terraform plan -out=plan.tfplan)  # ← targeted, not all modules
    done
```

**🛡️ Prevention**
- Set up `CODEOWNERS` so module changes require module-owner approval
- Use `when_modified` patterns in Atlantis to scope plan triggers to changed files

> ⚠️ **Never:** Use a polyrepo with local module paths — modules must be published to a registry or git tags for cross-repo use

---

# 🔴 Slide 3 · Scenario: Module Versioning Strategy

**🏗️ Setup**
> *Your team uses both public registry modules and internal Git-hosted modules across prod, staging, and dev environments.*

**❓ The Question**
What is your module versioning strategy and why does it differ by environment?

**🔍 Diagnosis**
1. Prod needs stability — pin to exact versions
2. Staging can tolerate patch updates — use `~>` constraint
3. Dev can use latest — fast iteration is the priority
4. Internal modules must use git tags, never branch refs

**✅ Fix**
```hcl
# Production: exact pin — zero surprise upgrades
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"  # ← never changes without explicit update
}

# Development: allow patches
module "vpc_dev" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"  # ← allows 5.1.x, not 5.2.0
}

# Internal modules: always use git tags, never branch refs
module "eks" {
  source = "git::https://github.com/myorg/modules.git//eks?ref=v2.3.0"
  # ← ?ref=v2.3.0 is immutable; ?ref=main changes daily
}
```

**🛡️ Prevention**
- Lint CI to block `source` references with branch refs in prod directories
- Run `terraform init -upgrade` on a schedule to detect available updates

> ⚠️ **Never:** Use `?ref=main` or `?ref=master` for module source in any non-dev environment — mutable branches make infra non-deterministic

---

# 🔴 Slide 4 · Scenario: Environment-Specific Configuration

**🏗️ Setup**
> *You manage prod, staging, and dev environments. Instance sizes, HA settings, and retention policies differ across environments.*

**❓ The Question**
How do you manage environment-specific configuration without duplicating code?

**🔍 Diagnosis**
1. Use a single `locals` map keyed by environment name
2. Derive all environment-specific values from `local.env`
3. Resources consume `local.env.*` — no environment conditionals scattered through code

**✅ Fix**
```hcl
# config.tf — single source of truth for all environment differences
locals {
  config = {
    prod    = { instance_type = "m5.2xlarge", multi_az = true,  log_retention = 90 }
    staging = { instance_type = "t3.large",   multi_az = false, log_retention = 14 }
    dev     = { instance_type = "t3.medium",  multi_az = false, log_retention = 7  }
  }
  env = local.config[var.environment]  # ← single lookup, used everywhere below
}

resource "aws_db_instance" "main" {
  instance_class      = local.env.instance_type  # ← no if/else anywhere
  multi_az            = local.env.multi_az
  deletion_protection = local.env.deletion_protection
}
```

**🛡️ Prevention**
- Add a `validation` block on `var.environment` to reject unknown values
- Keep the config map in a dedicated `config.tf` so it's easy to find and review

> ⚠️ **Never:** Scatter `var.environment == "prod" ? ... : ...` conditionals throughout resource blocks — it becomes unmaintainable and error-prone

---

# 🔴 Slide 5 · Scenario: Large Scale — 1000+ Resources

**🏗️ Setup**
> *Your Terraform state has 1200 resources. Plans take 15 minutes. The team is blocked waiting for CI to complete.*

**❓ The Question**
How do you diagnose and fix slow Terraform plans at scale?

**🔍 Diagnosis**
1. Enable JSON logging to identify which resources are slow to refresh
2. Check for overly broad `depends_on` that serializes the dependency graph
3. Check for AWS API throttling from the provider
4. Evaluate whether the state file needs to be split

**✅ Fix**
```bash
# Step 1: Find slow resources
TF_LOG=JSON terraform plan 2>&1 | jq '.@message' | grep "Refreshing"

# Step 2: Skip refresh for known-good state in CI
terraform plan -refresh=false  # ← pair with nightly refresh-only runs

# Step 3: Reduce parallelism to avoid API throttling
terraform plan -parallelism=5  # ← default is 10
```

```hcl
# Step 4: Tune AWS provider retry behavior
provider "aws" {
  retry_mode  = "adaptive"  # ← auto backs off on throttle responses
  max_retries = 10
}
```

**🛡️ Prevention**
- Split monolithic state: networking, compute, data, security in separate files
- Set a 200-resource soft limit per state file as a team convention
- Run `terraform plan -refresh-only` nightly rather than refreshing on every plan

> ⚠️ **Never:** Use `depends_on` broadly on modules — it forces sequential refresh and destroys parallelism

---

# 🎤 Slide 6 · Follow-up Q&A

---

### Q: How do you share outputs between separate Terraform state files?
- **`terraform_remote_state`** — reads another state file directly; tight coupling, consumer must know producer's backend config
- **SSM Parameter Store** — producer writes values; consumer reads via `data "aws_ssm_parameter"`; loosely coupled, no direct state dependency — preferred for cross-team sharing
- **Terragrunt `dependency` block** — reads outputs from another module automatically, with mock support for planning

> 💬 **Say:** "Prefer SSM for cross-team sharing — it decouples the consumer from knowing where your state lives and doesn't require read access to the producer's state bucket."

---

### Q: Should Terraform manage the IAM role that CI uses to run Terraform?
- This is the bootstrapping problem — you can't use Terraform to create the role Terraform uses to run, at least not initially
- Create a minimal bootstrap IAM role manually with enough permissions to create the state bucket, DynamoDB table, and CI role
- Import that role into a `bootstrap` Terraform config and manage it from then on
- Never delete the bootstrap role even after Terraform manages it

> 💬 **Say:** "The bootstrap role is the chicken-and-egg exception — it starts as a manual creation and gets imported. After that, Terraform manages its own permissions."

---
