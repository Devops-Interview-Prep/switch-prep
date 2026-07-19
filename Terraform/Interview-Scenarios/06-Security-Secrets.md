# 🎤 Security & Secrets Management
**10 Slides · Anti-Patterns, Secrets Manager, Vault, SSM, State, IAM, OIDC, Scanning**

---

# 🔴 Slide 1 · Scenario: Secrets Anti-Patterns

**🏗️ Setup**
> *You're reviewing a PR. The RDS password is hardcoded in the HCL. A teammate says "it's fine, it's a private repo."*

**❓ The Question**
Why is hardcoding secrets in Terraform dangerous, even in a private repo?

**🔍 Diagnosis**
1. Hardcoded values appear in the state file — readable by anyone with state access
2. Hardcoded values appear in git history — permanent even after deletion
3. Hardcoded values appear in plan/apply output — logged in CI systems
4. Environment variables are visible in CI logs and process lists

**✅ Fix**
```hcl
# NEVER — hardcoded secrets in HCL
resource "aws_db_instance" "main" {
  password = "MyPassword123!"  # ← leaks to: state, git history, plan output, CI logs
}

# NEVER — secrets in tfvars committed to git
# db_password = "MyPassword123!"

# RISKY — env vars visible in CI debug logs and process list
# TF_VAR_db_password=MyPassword123! terraform apply
```

**🛡️ Prevention**
- Never store secret values in `.tf` or `.tfvars` files
- Mark all secret variables with `sensitive = true` to suppress plan/apply logging
- Encrypt state at rest with KMS
- Audit CI job logs to confirm sensitive values are redacted

> ⚠️ **Never:** Trust "private repo" as a security boundary — git history, state files, and CI logs are all separate attack surfaces

---

# 🔴 Slide 2 · Scenario: Correct Pattern — AWS Secrets Manager

**🏗️ Setup**
> *You need to provision an RDS instance and an ECS task that reads the DB password at runtime.*

**❓ The Question**
How do you provision and consume secrets without them ever landing in Terraform state?

**✅ Fix**
```hcl
# Gold standard: let AWS manage the password — never touches TF state
resource "aws_db_instance" "main" {
  manage_master_user_password   = true               # ← AWS auto-generates + stores in Secrets Manager
  master_user_secret_kms_key_id = aws_kms_key.rds.arn
}

# Reference a pre-existing secret — value never enters TF state
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/db/password"  # ← secret created outside Terraform
}

# ECS: inject at container start via valueFrom — not stored in TF state
resource "aws_ecs_task_definition" "app" {
  container_definitions = jsonencode([{
    name  = "app"
    secrets = [{
      name      = "DB_PASSWORD"
      valueFrom = data.aws_secretsmanager_secret_version.db.arn  # ← container runtime fetches it
    }]
  }])
}
```

**🛡️ Prevention**
- Prefer `manage_master_user_password` over passing a password variable to RDS
- Use ARN references in ECS task definitions so secrets are never read by Terraform
- Enable Secrets Manager automatic rotation for all database credentials

> ⚠️ **Never:** Read a `data "aws_secretsmanager_secret_version"` and pass `.secret_string` directly to a resource — the value enters state; use `valueFrom` ARN patterns instead

---

# 🔴 Slide 3 · Scenario: Correct Pattern — HashiCorp Vault

**🏗️ Setup**
> *Your org uses HashiCorp Vault. Terraform needs to read a database password from Vault during apply without storing a Vault token anywhere.*

**❓ The Question**
How do you integrate Terraform with Vault without hardcoding a Vault token?

**✅ Fix**
```hcl
# Configure Vault provider — authenticate via AWS IAM (no hardcoded token)
provider "vault" {
  address = "https://vault.internal:8200"
  auth_login {
    path = "auth/aws/login"           # ← Vault AWS auth method
    parameters = {
      role = "terraform-role"         # ← Vault role mapped to the CI's IAM role
    }
  }
}

data "vault_generic_secret" "db" {
  path = "secret/prod/database"      # ← read from Vault at plan/apply time
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db.data["password"]
  # NOTE: value IS read into TF state — encrypt state with KMS
}
```

**🛡️ Prevention**
- Use Vault dynamic secrets where possible — credentials generated on-demand and auto-expire
- Set short TTLs on Vault tokens issued to Terraform CI runs
- Audit Vault access logs to detect unexpected secret reads

> ⚠️ **Never:** Store a static Vault token in CI environment variables — use Vault's AWS auth method so the CI IAM role IS the credential

---

# 🔴 Slide 4 · Scenario: Correct Pattern — SSM Parameter Store

**🏗️ Setup**
> *You want a lightweight secrets solution for non-highly-sensitive config values alongside secure strings for passwords.*

**❓ The Question**
How do you use SSM Parameter Store with Terraform, and what should Terraform write vs only read?

**✅ Fix**
```hcl
# READ an existing secret — created outside Terraform by ops or rotation process
data "aws_ssm_parameter" "db_password" {
  name            = "/prod/database/password"
  with_decryption = true   # ← decrypt SecureString using KMS
}

# WRITE non-secret config parameters via Terraform (acceptable)
resource "aws_ssm_parameter" "app_config" {
  name  = "/prod/app/max_connections"
  type  = "String"        # ← plain String for non-sensitive config
  value = "100"
}

# NEVER write secrets via Terraform — value ends up in state
# resource "aws_ssm_parameter" "password" {
#   type  = "SecureString"
#   value = var.password   # ← stored in state in plaintext
# }
```

**🛡️ Prevention**
- Tag SSM parameters by environment and sensitivity level for auditability
- Restrict `ssm:GetParameter` with `with_decryption=true` to only the IAM roles that need it

> ⚠️ **Never:** Create `SecureString` SSM parameters via Terraform — the value is stored in state; use SSM console or a rotation Lambda to create the initial secret

---

# 🔴 Slide 5 · Scenario: Sensitive Values in State

**🏗️ Setup**
> *You've marked variables as `sensitive = true` but a teammate says the values are still visible if you run `terraform state show`.*

**❓ The Question**
What does `sensitive = true` actually protect, and what does it NOT protect?

**✅ Fix**
```hcl
variable "api_key" {
  type      = string
  sensitive = true   # ← redacted in: terraform plan, terraform apply, terraform output
}

# Sensitive propagates: output referencing sensitive input must also be sensitive
output "connection_string" {
  value     = "postgres://user:${var.api_key}@${aws_db_instance.main.endpoint}/db"
  sensitive = true   # ← required — Terraform errors without this
}

# State encryption: separate concern — sensitive values ARE in state
terraform {
  backend "s3" {
    encrypt    = true
    kms_key_id = "arn:aws:kms:us-east-1:123:key/abc"  # ← customer-managed key
  }
}
```

```bash
# sensitive = true does NOT hide values in state
terraform state show aws_db_instance.main   # ← shows ALL attributes including "sensitive" ones
terraform state pull | jq .                 # ← full state with all values in plaintext
```

**🛡️ Prevention**
- Enable KMS encryption on the S3 state bucket with a customer-managed key
- Restrict state bucket access to CI roles and Terraform operators only
- Enable S3 access logging on the state bucket for audit trail
- Rotate any secrets stored in state — assume state could be read by an attacker

> ⚠️ **Never:** Assume `sensitive = true` secures the state file — it only protects terminal output and CI logs; state encryption is entirely separate

---

# 🔴 Slide 6 · Scenario: IAM Least Privilege for Terraform

**🏗️ Setup**
> *You need to define IAM policies for two CI roles — one for plan (read-only) and one for apply (write).*

**❓ The Question**
What permissions does each role need, and why are they split?

**✅ Fix**
```json
// Plan role — read-only, used on every PR
{
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ec2:Describe*", "iam:Get*", "iam:List*",
      "rds:Describe*", "eks:Describe*",
      "s3:GetObject", "s3:ListBucket",
      "dynamodb:GetItem"
    ],
    "Resource": "*"
  }, {
    "Sid": "StateAccess",
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject", "dynamodb:PutItem", "dynamodb:DeleteItem"],
    "Resource": ["arn:aws:s3:::my-tf-state/prod/*",
                 "arn:aws:dynamodb:us-east-1:*:table/terraform-locks"]
  }]
}
```

**🛡️ Prevention**
- Scope the OIDC condition to specific branches: `ref:refs/heads/main` for apply, `ref:refs/pull/*` for plan
- Review CI role permissions quarterly — they tend to grow without housekeeping
- Use IAM Access Analyzer to identify unused permissions in CI roles

> ⚠️ **Never:** Use a single IAM role for both plan and apply — a compromised PR workflow would be able to destroy production infrastructure

---

# 🔴 Slide 7 · Scenario: OIDC for GitHub Actions

**🏗️ Setup**
> *Your CI pipeline currently uses long-lived AWS access keys stored in GitHub Secrets. You want to eliminate stored credentials entirely.*

**❓ The Question**
How do you configure OIDC so GitHub Actions can assume an AWS role with no stored credentials?

**✅ Fix**
```hcl
# Create the OIDC provider in AWS (once per account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "terraform_ci" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          # Restrict to specific repo + branch — forks and PRs cannot assume this role
          "token.actions.githubusercontent.com:sub" = "repo:myorg/myrepo:ref:refs/heads/main"
        }
      }
    }]
  })
}
```

**🛡️ Prevention**
- Scope OIDC conditions tightly to `refs/heads/main` for apply, `refs/pull/*` for plan
- OIDC credentials are short-lived and expire when the GitHub Actions job ends — no rotation needed

> ⚠️ **Never:** Use `StringLike` with a wildcard that allows fork PRs to assume the apply role — malicious PRs from forks could destroy production infrastructure

---

# 🔴 Slide 8 · Scenario: Checkov / tfsec Security Scanning

**🏗️ Setup**
> *You want to catch security misconfigurations in Terraform code before they reach production — integrated into the PR pipeline.*

**❓ The Question**
How do you integrate static analysis tools and handle intentional policy exceptions?

**✅ Fix**
```bash
# checkov: comprehensive static analysis
pip install checkov
checkov -d infrastructure/ --framework terraform
# Common findings:
# CKV_AWS_18:  S3 bucket missing access logging
# CKV_AWS_21:  S3 versioning not enabled
# CKV2_AWS_5:  Security group defined but not attached

# tfsec: fast, fewer false positives
brew install tfsec
tfsec infrastructure/
```

```hcl
# Suppress with documented reason (tfsec)
resource "aws_s3_bucket" "public" {
  #tfsec:ignore:AWS017  -- public bucket intentional for static website hosting
  bucket = "my-public-site"
}

# Suppress with documented reason (checkov)
resource "aws_s3_bucket" "public" {
  #checkov:skip=CKV_AWS_18: Access logging not needed — no PII on public static site
  bucket = "my-public-site"
}
```

**🛡️ Prevention**
- Add both tfsec and checkov as PR gates — they catch different things
- All inline suppressions must include a documented justification (enforced via PR review)
- Review suppression comments in quarterly security audits

> ⚠️ **Never:** Add a blanket suppression for all checks on a resource to "silence the noise" — address findings individually with documented justifications

---

# 🎤 Slide 9 · Follow-up Q&A

---

### Q: Terraform stores sensitive values in state. How do you prevent unauthorized state access?
- S3 bucket: block all public access, enable KMS encryption with a customer-managed key, enable versioning, enable access logging, restrict via IAM policy to CI role and Terraform operators only
- Never print state to CI logs — avoid `terraform state pull` in CI pipelines
- Use `sensitive = true` on variables and outputs to prevent values appearing in plan output
- Consider Terraform Cloud — encrypts state in transit and at rest with team-level access control
- Rotate any secrets that appear in state — assume state could be compromised

> 💬 **Say:** "`sensitive = true` protects your terminal and CI logs. KMS encryption protects the state file at rest. IAM policy protects who can read the file. All three are required."

---

### Q: How do you rotate a secret that Terraform manages?
- Best practice: don't store the secret value in Terraform at all
- For RDS: use `manage_master_user_password = true` — AWS handles rotation via Secrets Manager automatically
- For app secrets: create the secret in Secrets Manager outside Terraform; Terraform references only the ARN; rotation handled by Lambda or an external process
- If Terraform must write the value initially: use `lifecycle { ignore_changes = [password] }` so subsequent applies don't reset it to the original value

> 💬 **Say:** "The safest secret is one Terraform never reads — use manage_master_user_password for RDS and ARN references for everything else."

---

### Q: What's the risk of using `TF_VAR_` environment variables for secrets in CI?
- CI runners often print environment variables on job startup in debug mode
- The `env` command output in CI is frequently captured in logs
- The variable value still ends up in the state file — same risk as any method
- Process list (`ps aux`) on shared CI runners can expose environment variables
- Better approach: OIDC + AWS Secrets Manager — no credentials in environment variables at all; the CI runner gets a temporary token via OIDC and secrets are fetched from Secrets Manager at runtime

> 💬 **Say:** "Environment variables are a step better than hardcoding, but they're not a solution — they leak through CI logs, ps output, and still land in state. OIDC + Secrets Manager is the real fix."

---
