# ⚡ Terraform CLI Commands
**25 Slides · Full Command Lifecycle, All Subcommands + Environment Variables**

---

# 🎯 Slide 1 · Format Your Terraform Code

`terraform fmt` rewrites `.tf` files to canonical HCL style — think `gofmt` for Terraform.

```bash
# WHAT THIS DEMONSTRATES: fmt flags from local use to CI gate
terraform fmt                        # reformat files in current directory
terraform fmt --recursive            # ← also format all subdirectories
terraform fmt --diff                 # ← show diff between original and formatted
terraform fmt --check --recursive    # ← non-zero exit if files need formatting (CI gate)
```

> ✅ Rule: Always run `fmt --check --recursive` as the first CI step — catches style drift before wasting plan time.

> ⚠️ Watch out: `--check` only checks, it does NOT format. Run `fmt` (no flag) locally to auto-fix.

---

# 🔄 Slide 2 · Initialize Your Directory

`terraform init` prepares the working directory — must run before any other command.

```bash
# WHAT THIS DEMONSTRATES: common init variants
terraform init                              # standard init
terraform init -upgrade                     # ← bump providers to latest allowed version
terraform init -reconfigure                 # ← reinit backend, no state migration
terraform init -migrate-state               # ← move state to new backend
terraform init -backend=false               # ← skip backend (local dev only)
terraform init -backend-config=partial.hcl  # ← merge partial backend config
```

- **Backend init** — sets up local/S3/etcd backend, fetches remote state
- **Provider download** — downloads correct versions into `.terraform/`
- **Module install** — downloads and caches modules
- **Lock file** — creates/updates `terraform.lock.hcl`

> ✅ Rule: Always commit `terraform.lock.hcl` — it guarantees every teammate and CI runner uses identical provider versions.

> ⚠️ Watch out: `-reconfigure` and `-migrate-state` are mutually exclusive. Use `-migrate-state` when switching backends.

---

# ✅ Slide 3 · Validate Your Terraform Code

Checks syntax and semantic correctness — no API calls, no state access.

```bash
# WHAT THIS DEMONSTRATES: validate in sequence
terraform init
terraform validate           # ← syntax + schema check (requires init first)
terraform validate -json     # ← machine-readable output for automation
```

- Run `terraform init` first — validators need downloaded providers
- Checks for missing required arguments and invalid references
- Does NOT check runtime errors or wrong resource IDs
- Does NOT validate AWS credentials — only checks config structure

> ✅ Rule: `validate` catches config errors cheaply — zero API calls, runs in seconds.

> ⚠️ Watch out: `validate` passes even if your AWS credentials are wrong — it only checks the config, not the real world.

---

# ⚡ Slide 4 · Plan Your Changes

```bash
# WHAT THIS DEMONSTRATES: plan flags from basic to CI/CD-safe
terraform plan                        # show execution plan (interactive)
terraform plan -out=plan.tfplan       # ← save plan to file (use in CI/CD)
terraform plan -target=ADDR           # ← plan only specific resource
terraform plan -var="key=val"         # ← pass variable inline
terraform plan -var-file=f.tfvars     # ← pass variable file
terraform plan -refresh=false         # ← skip state refresh (faster, stale)
terraform plan -refresh-only          # ← only refresh state, no changes
terraform plan -destroy               # ← preview what destroy would do (safe)
terraform plan -compact-warnings      # ← suppress duplicate warnings
terraform plan -json                  # ← machine-readable JSON output
```

> ✅ Rule: Always use `plan -out=plan.tfplan` in CI — the saved plan is a cryptographic contract between state and apply.

> ⚠️ Watch out: `plan -refresh=false` is faster but uses potentially stale state — only safe when you know nothing changed outside Terraform.

---

# ⚡ Slide 5 · Apply Your Changes

```bash
# WHAT THIS DEMONSTRATES: apply variants from interactive to full automation
terraform apply                                    # interactive: shows plan, requires "yes"
terraform apply plan.tfplan                        # ← apply a saved plan (no re-plan)
terraform apply -auto-approve                      # ← skip "yes" prompt (CI/CD)
terraform apply -var-file="varfile.tfvars"         # ← load variables from file
terraform apply -var="environment=dev"             # ← inline variable override
terraform apply -target=aws_instance.ec2_example   # ← apply only one resource
terraform apply -parallelism=20                    # ← concurrent ops (default: 10)
terraform apply -replace=aws_instance.web          # ← force destroy + recreate
terraform apply -refresh=false                     # ← skip state refresh before apply
```

> ✅ Rule: In CI/CD always use `plan -out=plan.tfplan` then `apply plan.tfplan` — never `apply -auto-approve` on a fresh run.

> ⚠️ Watch out: `-target` is for emergency use only — regular use leads to drift between targeted and untargeted resources.

---

# 💥 Slide 6 · Destroy Commands

```bash
# WHAT THIS DEMONSTRATES: targeted vs full destroy
terraform plan -destroy            # ← preview what destroy would do (safe, do this first)
terraform destroy                  # destroy ALL managed resources
terraform destroy -target=ADDR     # ← destroy only specific resource
terraform destroy -auto-approve    # ← skip confirmation (dangerous in prod!)
```

> ✅ Rule: Always run `terraform plan -destroy` first to review what will be deleted before running actual destroy.

> ⚠️ Watch out: `terraform destroy -auto-approve` in a production pipeline is an incident waiting to happen — require manual approval via GitHub environment gates.

---

# 🎯 Slide 7 · Import Existing Resources

Bring existing infrastructure under Terraform management without recreating it.

```bash
# WHAT THIS DEMONSTRATES: classic import workflow
terraform import aws_s3_bucket.my_bucket my-bucket-name
# ← RESOURCE_TYPE.RESOURCE_NAME  REAL_RESOURCE_ID
```

```hcl
# WHAT THIS DEMONSTRATES: Terraform 1.5+ declarative import block
import {
  to = aws_instance.web
  id = "i-1234567890abcdef0"   # ← the real AWS instance ID
}
```

- Create an empty resource block in your `.tf` file first
- Run `terraform import` to pull it into state
- Fill in the resource block arguments (copy from `terraform state show`)
- Run `terraform plan` — should show no changes if complete

> ✅ Rule: After import, always run `terraform plan` and confirm zero planned changes before committing.

> ⚠️ Watch out: You must have a matching resource block in your config BEFORE running import — otherwise it errors.

---

# 🔄 Slide 8 · State Management Commands

State is Terraform's source of truth. Handle with care.

```bash
# WHAT THIS DEMONSTRATES: full state subcommand set
terraform state list                        # ← list all tracked resources
terraform state show aws_instance.web       # ← show all attributes of one resource
terraform state mv aws_instance.old \
               aws_instance.new             # ← rename/move (refactoring, no infra change)
terraform state rm my_resource              # ← remove from state (resource still exists!)
terraform state pull                        # ← download state as JSON
terraform state push file.tfstate           # ← upload local state to backend
terraform force-unlock LOCK_ID              # ← release stuck state lock
```

> ✅ Rule: `state rm` removes Terraform's tracking of a resource — the real resource is untouched. Use `terraform destroy` to actually delete it.

> ⚠️ Watch out: `state mv` is safe for refactoring (renaming modules, reorganizing resources) — no infrastructure change happens.

---

# 🔍 Slide 9 · Output, Show, Graph, Providers

```bash
# WHAT THIS DEMONSTRATES: inspection and visualization commands
terraform output                          # print all root outputs
terraform output vpc_id                   # ← print one specific output
terraform output -json                    # ← machine-readable (use in scripts)

terraform show                            # show current state (human readable)
terraform show plan.tfplan                # ← show a saved plan file

terraform graph | dot -Tsvg > graph.svg   # ← visualize dependency graph in browser

terraform providers                       # show providers in current config
terraform providers lock                  # update the lock file
terraform providers mirror ./mirror       # ← download providers locally (air-gapped)

terraform refresh                         # sync state with real infra (deprecated)
```

> ✅ Rule: Use `terraform output -json` in CI to pass values between pipeline stages (e.g., pass VPC ID to the next job).

> ⚠️ Watch out: `terraform refresh` is deprecated — `terraform plan -refresh-only` is the modern equivalent and is safer.

---

# 🔄 Slide 10 · Workspace Commands

Workspaces let you use one config with multiple state files (e.g., dev/staging/prod).

```bash
# WHAT THIS DEMONSTRATES: workspace lifecycle
terraform workspace list           # list all workspaces
terraform workspace show           # ← show current workspace name
terraform workspace new staging    # ← create and switch to "staging"
terraform workspace select prod    # ← switch to existing "prod"
terraform workspace delete old     # ← delete (workspace must be empty)
```

- Access current workspace in config via `terraform.workspace`
- Use for naming: `"${var.prefix}-${terraform.workspace}"`
- Workspaces share the same backend and config
- NOT a replacement for separate environments with separate backends

> ✅ Rule: Workspaces are best for minor environment variations — use separate root modules + backends for true environment isolation.

> ⚠️ Watch out: Workspaces share the same config — a mistake in one workspace's plan can affect what you think you're applying elsewhere.

---

# 🆚 Slide 11 · Taint vs -replace

```bash
# WHAT THIS DEMONSTRATES: old vs new way to force resource recreation

# OLD (deprecated in Terraform 1.3 — modifies state directly, risky):
terraform taint aws_instance.web     # mark for recreation
terraform untaint aws_instance.web   # unmark

# NEW (plan-time flag — safe, visible in plan output):
terraform apply -replace=aws_instance.web   # ← force destroy + recreate
```

| | `taint` (deprecated) | `-replace` (modern) |
|---|---|---|
| When introduced | Pre-1.3 | Terraform 0.15.2+ |
| How it works | Writes directly to state | Plan-time flag |
| Plan visibility | No — hidden | Yes — shown in plan |
| Risk | State divergence window | Safe |

> ✅ Rule: Always use `-replace=ADDR` — it shows intent in the plan, doesn't touch state, and is supported in all modern Terraform versions.

> ⚠️ Watch out: `taint` wrote directly to the state file, creating a window where state and reality diverged. `-replace` eliminates that risk.

---

# 🔄 Slide 12 · CI/CD GitHub Actions Pipeline

```yaml
# WHAT THIS DEMONSTRATES: production-grade GitHub Actions Terraform pipeline
name: Terraform
on:
  pull_request:
    paths: ['terraform/**']   # ← only run when terraform files change
  push:
    branches: [main]
jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      id-token: write        # ← needed for OIDC auth to AWS
      pull-requests: write   # ← needed to post plan comment
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0   # ← pin exact version
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/TerraformCIRole  # ← OIDC, no keys
          aws-region: us-east-1
      - run: terraform init
      - run: terraform validate
      - run: terraform fmt -check -recursive   # ← fails pipeline if unformatted
      - run: terraform plan -out=plan.tfplan -no-color 2>&1 | tee plan.txt
  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'     # ← only on merge to main
    environment: production                 # ← requires manual approval in GitHub
    steps:
      - run: terraform init
      - run: terraform apply -auto-approve plan.tfplan  # ← applies the SAVED plan
```

> ✅ Rule: The `plan` job saves `plan.tfplan`; the `apply` job applies exactly that saved plan — this is the only safe CI/CD pattern.

> ⚠️ Watch out: The artifact (plan.tfplan) must be passed between jobs via `actions/upload-artifact` / `download-artifact` — abbreviated above for clarity.

---

# 🖥️ terraform console — Interactive Expression REPL

`terraform console` opens an interactive shell for evaluating HCL expressions against real state.
Think of it as a sandbox to test expressions before putting them in your config.

```bash
terraform console   # ← opens interactive prompt; Ctrl-D or "exit" to quit
```

**What you can do inside the console:**

```hcl
# Test string functions
> upper("hello")
"HELLO"

> format("app-%s-%03d", "web", 1)
"app-web-001"

# Test cidr math
> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"

> cidrsubnet("10.0.0.0/16", 8, 0)
"10.0.0.0/24"

# Inspect actual state values
> aws_instance.web.public_ip     # ← reads live state
"52.23.1.2"

> aws_instance.web.tags
{ Environment = "dev", Name = "web-server" }

# Test data source values
> data.aws_ami.ubuntu.id
"ami-0abcdef1234567890"

# Test for expressions before writing them in HCL
> [for s in ["a", "b", "c"] : upper(s)]
["A", "B", "C"]

# Test lookup and merge
> lookup({ dev = "t3.micro", prod = "m5.xlarge" }, "dev", "t3.small")
"t3.micro"

# Check if a condition works
> var.environment == "prod" ? "m5.xlarge" : "t3.micro"
"t3.micro"   # (assuming var.environment = "dev")
```

**Non-interactive (pipe an expression):**
```bash
echo 'cidrsubnet("10.0.0.0/16", 8, 5)' | terraform console
# "10.0.5.0/24"
```

> ✅ Rule: Always test `cidrsubnet`, `for` expressions, and `templatefile` results in `terraform console` before using them in your config — it saves plan/apply cycles.

---

# 📦 terraform version + terraform get

**`terraform version` — check what you have installed:**
```bash
terraform version
# Terraform v1.6.6
# on darwin_amd64
# + provider registry.terraform.io/hashicorp/aws v5.31.0
# + provider registry.terraform.io/hashicorp/random v3.6.0

terraform version -json   # ← machine-readable for CI checks
# {
#   "terraform_version": "1.6.6",
#   "platform": "darwin_amd64",
#   "provider_selections": { "registry.terraform.io/hashicorp/aws": "5.31.0" }
# }
```

**Why it matters:**
- Verify the version matches your required_version constraint
- CI pipelines should pin exact version; check actual version vs. pinned in pipeline
- `-json` lets a script assert the version before proceeding

---

**`terraform get` — download modules without full init:**
```bash
terraform get             # download/update modules listed in config
terraform get -update     # ← force re-download even if already cached
```

**How it differs from `terraform init`:**

| Command | Downloads Providers | Downloads Modules | Configures Backend |
|---|---|---|---|
| `terraform init` | ✅ | ✅ | ✅ |
| `terraform get` | ❌ | ✅ | ❌ |

Use `terraform get` when:
- You only changed module sources (added a new module block)
- You want to update a module to its latest version
- Running `init` again would take too long (e.g., providers already cached)

```bash
# Practical example: added a new module, don't want to re-download providers
terraform get -update   # just update the module cache
terraform plan          # providers already in .terraform/
```

> ⚠️ Watch out: `terraform get` does NOT create or update the lock file. Run `terraform init` when you change provider requirements.

---

# 🔐 terraform login + terraform logout

Used for authenticating to **HCP Terraform** (formerly Terraform Cloud) or a self-hosted Terraform Enterprise instance.

**`terraform login`:**
```bash
terraform login                           # authenticate to app.terraform.io (HCP Terraform)
terraform login tfe.company.com           # ← authenticate to self-hosted TFE
```

What happens:
1. Opens a browser at the HCP Terraform login page
2. You log in and create an API token
3. Token is stored in `~/.terraform.d/credentials.tfrc.json`
4. Subsequent commands (init, plan, apply) use this token to reach the remote backend

**The token file:**
```json
{
  "credentials": {
    "app.terraform.io": {
      "token": "abcdef123456789..."
    }
  }
}
```

**`terraform logout`:**
```bash
terraform logout                   # removes token for app.terraform.io
terraform logout tfe.company.com   # ← removes token for specific host
```

**In CI/CD (no browser available):**
```bash
# Set the token via environment variable — never runs browser
export TF_TOKEN_app_terraform_io="abcdef123456"
# ← underscores replace dots and hyphens in the hostname
terraform init  # ← picks up the token from env var automatically
```

> ✅ Rule: In CI/CD, use `TF_TOKEN_<hostname>` env var (injected from secrets manager). Never commit tokens or put them in config files.

---

# 🧪 terraform test — Automated Testing (Terraform 1.6+)

`terraform test` runs `.tftest.hcl` files that assert your config does what it claims.

**File structure:**
```
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
    tests/
      vpc_basic.tftest.hcl   ← test file
```

**A test file (`vpc_basic.tftest.hcl`):**
```hcl
# Declare what variables to use for the test
variables {
  vpc_cidr   = "10.0.0.0/16"
  name_prefix = "test"
}

# A "run" block is one test scenario
run "creates_vpc_with_correct_cidr" {
  command = plan   # ← use "apply" to actually create resources

  # Assert expressions — if false, test fails
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR does not match input variable"
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Expected 2 private subnets, got ${length(aws_subnet.private)}"
  }
}

run "uses_correct_tags" {
  command = plan

  assert {
    condition     = aws_vpc.main.tags["Environment"] == "test"
    error_message = "Environment tag missing or wrong"
  }
}
```

**Running tests:**
```bash
terraform test                          # run all .tftest.hcl files
terraform test -filter=tests/vpc_basic  # ← run one specific test file
terraform test -verbose                 # ← show all assertions (pass + fail)
terraform test -json                    # ← machine-readable output for CI
```

**Two test modes:**

| Mode | `command = plan` | `command = apply` |
|---|---|---|
| Creates real resources | ❌ | ✅ |
| Tests real outputs | ❌ | ✅ |
| Speed | Fast (seconds) | Slow (minutes) |
| Cost | Free | Charges apply |
| Cleans up after | N/A | ✅ Auto-destroys |

**Using `mock_provider` for unit testing (no AWS calls):**
```hcl
mock_provider "aws" {
  mock_resource "aws_vpc" {
    defaults = {
      id         = "vpc-mock12345"
      cidr_block = "10.0.0.0/16"
    }
  }
}

run "unit_test_no_aws" {
  command = plan   # ← uses mock values, no AWS credentials needed
  assert {
    condition     = output.vpc_id == "vpc-mock12345"
    error_message = "VPC ID should come from the mock"
  }
}
```

> ✅ Rule: Use `command = plan` with mocks for fast unit tests in PRs; use `command = apply` in nightly pipelines to validate real infrastructure creation and cleanup.

---

# 🔄 terraform state replace-provider

Rewrites provider source addresses in the state file — needed when a provider moves from the old registry format to the new one.

**When do you need this?**
- Migrating from the old-style `hashicorp/kubernetes` to a community fork
- A provider changed its registry address (e.g., `terraform-providers/datadog` → `datadog/datadog`)
- You want to switch from HashiCorp's AWS provider to an alternative

```bash
# Syntax:
terraform state replace-provider OLD_PROVIDER_SOURCE NEW_PROVIDER_SOURCE

# Example: migrate Datadog provider to new address
terraform state replace-provider \
  registry.terraform.io/terraform-providers/datadog \
  registry.terraform.io/datadog/datadog
```

**What it does:**
1. Updates every resource in state that was managed by the old provider
2. Changes the provider address in the state file only — no API calls, no infra changes
3. After this, `terraform init` and `terraform plan` use the new provider

**Full workflow:**
```bash
# Step 1: Update your required_providers block in versions.tf
source = "datadog/datadog"   # ← changed from "terraform-providers/datadog"

# Step 2: Run state replace-provider
terraform state replace-provider \
  registry.terraform.io/terraform-providers/datadog \
  registry.terraform.io/datadog/datadog

# Step 3: Re-init to download the new provider
terraform init -upgrade

# Step 4: Confirm no changes
terraform plan   # → "No changes" if provider API is compatible
```

> ⚠️ Watch out: This rewrites state — back up your state file or use S3 versioning before running. With `-auto-approve`, it skips the confirmation prompt (risky).

---

# 🔓 terraform force-unlock — When State Gets Stuck

When a Terraform process is killed mid-apply, the DynamoDB lock remains. No one else can run apply until the lock is released.

```bash
# See the lock info (error message when acquiring the lock):
# Error: Error acquiring the state lock
#   Lock Info:
#     ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
#     Path:      s3://mybucket/env/dev/terraform.tfstate
#     Operation: OperationTypeApply
#     Who:       pawan@laptop
#     Version:   1.6.6
#     Created:   2024-01-15 09:23:11 UTC

# Release the lock using the ID from the error message:
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890

# Skip the confirmation prompt:
terraform force-unlock -force a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**What it does:**
- Deletes the DynamoDB item with `LockID = "s3://bucket/path"` 
- Does NOT affect the state file — only removes the lock record

**How to find the Lock ID without an error message:**
```bash
# Check DynamoDB directly
aws dynamodb scan \
  --table-name terraform-state-locks \
  --query 'Items[*].{ID:LockID.S,Info:Info.S}'

# Or pull state and check the lock field
terraform state pull | jq '.serial'
```

**When is force-unlock safe?**
- ✅ The process that held the lock is confirmed dead (CI job cancelled, laptop crashed)
- ✅ You verified no other `terraform apply` is currently running
- ❌ Never unlock if you're unsure whether another apply is still in progress — two concurrent applies can corrupt state

**Recovery workflow after a failed apply:**
```bash
terraform force-unlock <LOCK_ID>   # release stuck lock
terraform plan                      # check what actually completed vs what didn't
terraform apply                     # apply remaining changes
```

> ⚠️ Watch out: Force-unlocking while another apply is running leads to two writers — state corruption is very likely. Confirm the lock-holder process is dead before unlocking.

---

# 📋 terraform providers schema + Lock File Management

**`terraform providers schema` — inspect what attributes a provider supports:**
```bash
terraform providers schema -json | jq '.provider_schemas | keys'
# ["registry.terraform.io/hashicorp/aws"]

# Find all attributes of aws_instance
terraform providers schema -json | jq '
  .provider_schemas["registry.terraform.io/hashicorp/aws"]
  .resource_schemas["aws_instance"]
  .block.attributes | keys'
# ["ami", "arn", "availability_zone", "cpu_core_count", ...]
```

**Use cases:**
- Discover all valid arguments for a resource without reading docs
- Automation that generates Terraform config from a provider's schema
- Verify what attributes are available before writing `terraform state show`

---

**`.terraform.lock.hcl` — the provider lock file:**
```hcl
# .terraform.lock.hcl (auto-generated, commit this file)
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:abc123...",   # ← content hash, verified on every init
    "zh:def456...",
  ]
}
```

**Lock file commands:**
```bash
# Update the lock file for a specific provider
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  registry.terraform.io/hashicorp/aws
# ← downloads hashes for BOTH platforms (needed if devs use Mac, CI uses Linux)

# Download providers to a local directory (air-gapped / offline environments)
terraform providers mirror ./providers-mirror
# Creates: ./providers-mirror/registry.terraform.io/hashicorp/aws/5.31.0/...

# Then use the mirror in init:
terraform init -plugin-dir=./providers-mirror
```

> ✅ Rule: If your team uses macOS (arm64) and CI runs on Linux (amd64), run `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64` and commit the resulting lock file — otherwise CI fails with "hash mismatch."

---

# 🎯 plan -detailed-exitcode + -generate-config-out

**`-detailed-exitcode` — machine-readable plan result for CI:**
```bash
terraform plan -detailed-exitcode
echo $?
# Exit codes:
#   0 → success, no changes (infra matches config)
#   1 → error
#   2 → success, changes are pending (resources would be modified)
```

**Using it in a CI script:**
```bash
terraform plan -detailed-exitcode -out=plan.tfplan
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "No changes — skipping apply"
elif [ $EXIT_CODE -eq 2 ]; then
  echo "Changes detected — proceeding to apply"
  terraform apply plan.tfplan
else
  echo "Plan failed"
  exit 1
fi
```

This lets your pipeline skip the apply step when there's nothing to change — faster, safer.

---

**`-generate-config-out` — generate HCL from an import block (Terraform 1.5+):**

Problem: you have an `import` block pointing at an existing resource, but you haven't written the resource block yet.

```hcl
# main.tf — only the import block
import {
  to = aws_vpc.legacy
  id = "vpc-0abc123def456"
}
```

```bash
# Generate the resource block automatically from the real resource:
terraform plan -generate-config-out=generated.tf

# generates generated.tf:
resource "aws_vpc" "legacy" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = { Name = "legacy-vpc" }
}
```

Now you have the HCL — copy it to `main.tf`, delete `generated.tf`, and run `terraform apply` to import.

> ✅ Rule: `-generate-config-out` saves hours when importing large existing resources — let Terraform write the HCL from the real AWS attributes instead of hand-crafting it.

---

# 🌍 Terraform Environment Variables — Full Reference

These control Terraform behavior without touching `.tf` files — essential for CI/CD.

**Debugging:**
```bash
TF_LOG=DEBUG terraform plan   # log levels: TRACE, DEBUG, INFO, WARN, ERROR, JSON
TF_LOG=JSON terraform apply   # structured JSON logs (pipe to jq for filtering)
TF_LOG_PATH=/tmp/tf.log terraform plan  # write logs to file instead of stderr
TF_LOG_CORE=INFO      # ← log level for Terraform Core only (1.1+)
TF_LOG_PROVIDER=DEBUG # ← log level for provider plugin only (1.1+)
```

**Variable injection:**
```bash
# TF_VAR_<name> sets input variables — equivalent to -var="name=value"
export TF_VAR_environment="prod"
export TF_VAR_instance_type="m5.xlarge"
export TF_VAR_db_password="secret123"   # ← preferred for secrets (never in .tf files)
terraform apply  # picks up TF_VAR_* automatically
```

**CLI argument defaults:**
```bash
# TF_CLI_ARGS sets default flags for ALL commands
export TF_CLI_ARGS="-no-color"   # ← useful in CI (strips ANSI escape codes from logs)

# TF_CLI_ARGS_<subcommand> sets defaults for a specific subcommand
export TF_CLI_ARGS_plan="-compact-warnings -no-color"
export TF_CLI_ARGS_apply="-no-color"
export TF_CLI_ARGS_init="-upgrade"

terraform plan  # equivalent to: terraform plan -compact-warnings -no-color
```

**Workspace and directories:**
```bash
TF_WORKSPACE=prod terraform plan
# ← equivalent to: terraform workspace select prod && terraform plan
# Useful in CI — no need to run workspace select first

TF_DATA_DIR=/tmp/tf-cache terraform init
# ← moves .terraform/ directory to a custom location
# Useful when working directory is read-only (some CI systems)

TF_CLI_CONFIG_FILE=/path/to/custom/.terraformrc
# ← use a non-default CLI config file (provider mirrors, credentials)
```

**Input and output control:**
```bash
TF_INPUT=false terraform apply
# ← disables interactive prompts — if a variable has no value, apply fails immediately
# Equivalent to -input=false; always set this in CI

TF_IN_AUTOMATION=true
# ← adjusts output formatting for CI (slightly different prompt text)
# Convention: set it in CI pipelines to get cleaner output

TF_REGISTRY_DISCOVERY_RETRY=5
# ← retry count for registry lookups (useful in unreliable network environments)
```

**Full CI environment block example:**
```bash
export TF_INPUT=false
export TF_IN_AUTOMATION=true
export TF_CLI_ARGS="-no-color"
export TF_VAR_environment="prod"
export TF_VAR_db_password="${{ secrets.DB_PASSWORD }}"
export TF_LOG=INFO
export TF_LOG_PATH=/var/log/terraform.log
```

> ⚠️ Watch out: `TF_CLI_ARGS` applies to ALL subcommands — including `destroy`. A flag like `-auto-approve` in `TF_CLI_ARGS` is extremely dangerous. Use `TF_CLI_ARGS_apply` and `TF_CLI_ARGS_plan` to scope it.

---

# 🔒 Lock Flags — -lock and -lock-timeout

Terraform acquires a state lock at the start of plan and apply. These flags control that behavior.

```bash
terraform plan  -lock=false         # ← skip locking entirely (DANGEROUS)
terraform apply -lock=false         # ← apply without acquiring lock

terraform plan  -lock-timeout=5m    # ← wait up to 5 minutes for the lock to release
terraform apply -lock-timeout=10m   # ← useful when two pipelines might collide
```

**When is `-lock=false` ever safe?**
- Reading state for inspection only (`terraform show`, `terraform state list`)
- You are the only person with access to this workspace and it's development only
- Debugging a stuck lock that `force-unlock` can't fix

**`-lock-timeout` is the safer alternative:**
```bash
# Instead of skipping locking entirely:
terraform apply -lock-timeout=5m
# ← Terraform will WAIT 5 minutes for the lock to release
# ← If another apply finishes in that window, yours proceeds safely
# ← If the lock doesn't release in time, yours fails with an error
```

**Lock timeout in CI/CD:**
```yaml
# GitHub Actions — set a timeout if two pipelines can collide
- run: terraform apply plan.tfplan -lock-timeout=3m
```

> ⚠️ Watch out: `-lock=false` removes the only concurrency safety net. Two applies running simultaneously against the same state WILL corrupt it. Only use it when you have absolute certainty you're the only one touching this workspace.

---

# 🎤 Slide 13 · Interview Q&A — Saved Plan Rationale

**Q: Why save the plan with `-out` in CI/CD instead of running plan then apply separately?**

- Without `-out`, plan and apply run as two independent operations
- Between them, someone else could merge code or a resource could change externally
- The apply re-plans automatically — may produce different results than what was reviewed
- With `-out=plan.tfplan`: the plan is cryptographically tied to the state version at planning time
- If state changed between plan and apply, Terraform errors rather than applying something unreviewed

> 💬 **Say:** "The saved plan is a cryptographic contract between the state at plan time and the apply — any drift causes it to fail safely."

---

# 🎤 Slide 14 · Interview Q&A — Taint vs -replace

**Q: `terraform apply -replace` vs `taint` — what's the difference?**

- `terraform taint` was deprecated in Terraform 1.3
- It wrote directly to state to mark a resource as tainted — risky (state modification mid-workflow)
- `-replace=ADDR` is a plan-time flag — forces recreation without touching state
- It's safer: intent is visible in the plan output before anything is applied
- Both result in the same behavior: destroy then create the resource

> 💬 **Say:** "taint modifies state; -replace stays in plan-space — it's safer and auditable."

---

# 🎤 Slide 15 · Interview Q&A — Parallelism

**Q: What does `-parallelism=N` control and when would you tune it?**

- Controls how many resource operations run concurrently (default: 10)
- Increase for large configs with many independent resources to speed up applies
- Decrease if hitting API rate limits (AWS frequently throttles at high concurrency)
- Some providers have internal concurrency limits regardless of this flag
- At `0`, operations are fully sequential

> 💬 **Say:** "Default is 10; tune down when you hit AWS throttling, tune up when you have many independent resources and fast APIs."

---

# 🎤 Interview Q&A — terraform console Use Cases

**Q: When would you use `terraform console` in day-to-day work?**

Three situations where it saves real time:

1. **Debugging CIDR math before applying** — `cidrsubnet("10.0.0.0/16", 8, 3)` → see the result instantly without plan/apply
2. **Testing `for` expressions and `lookup` logic** — write `[for k, v in var.tags : "${k}=${v}"]`, verify it before putting it in the config
3. **Inspecting real state values** — `aws_instance.web.private_ip` reads live state and prints the actual IP; useful when you need to grab a value without running `terraform state show`

> 💬 **Say:** "console is my scratchpad — I test every cidrsubnet, every for expression, and every lookup there before I commit it to the config."

---

# 🎤 Interview Q&A — terraform test vs Manual Testing

**Q: What is `terraform test` and how is it different from just running `terraform plan`?**

- `terraform plan` tells you what WILL happen — it does not assert that the outcome is correct
- `terraform test` runs `.tftest.hcl` files that assert SPECIFIC conditions about what the plan or apply produces
- Example: `assert { condition = length(aws_subnet.private) == 3 }` fails the test if the module creates 2 or 4 subnets — plan alone would not catch that
- `command = plan` mode: zero API cost, runs in seconds, great for PR gates
- `command = apply` mode: creates real resources, verifies real outputs, auto-destroys — for nightly validation

> 💬 **Say:** "`plan` is a preview; `test` is a contract. `test` lets me assert that a module's outputs satisfy specific conditions — not just that it runs without error."

---

# 🎤 Interview Q&A — Stuck Lock Recovery

**Q: A Terraform apply was killed mid-run in CI. Now no one can apply. What do you do?**

Step by step:
1. Confirm the lock-holding process is truly dead — check the CI job, check if any colleague is running apply
2. Get the Lock ID from the error message (`Error acquiring the state lock → ID: <uuid>`) or scan DynamoDB directly
3. Run `terraform force-unlock <LOCK_ID>` — this deletes the DynamoDB lock record only; state file is untouched
4. Run `terraform plan` to check what the killed apply completed vs what it didn't
5. Run `terraform apply` to finish the partial work

**What NOT to do:** do not use `-lock=false` to bypass locking going forward — that removes your only concurrency guard. Fix the root cause (flaky CI, network timeout) instead.

> 💬 **Say:** "force-unlock is safe only after you confirm the lock-holder is dead. It deletes the DynamoDB item — nothing else. State is untouched."

---

# 🎤 Interview Q&A — Environment Variables in CI

**Q: How do you pass Terraform variables and configure behavior in a CI pipeline without modifying .tf files?**

Three layers:

| Layer | Mechanism | Example |
|---|---|---|
| Input variables | `TF_VAR_<name>` env var | `TF_VAR_db_password=${{ secrets.DB_PWD }}` |
| CLI flags | `TF_CLI_ARGS_<cmd>` | `TF_CLI_ARGS_plan="-no-color -compact-warnings"` |
| Behavior | Specific env vars | `TF_INPUT=false`, `TF_IN_AUTOMATION=true` |

The critical ones to always set in CI:
- `TF_INPUT=false` — fail immediately if a variable has no value instead of hanging on a prompt
- `TF_IN_AUTOMATION=true` — tells Terraform it's running in CI (cleaner output)
- `TF_CLI_ARGS="-no-color"` — strips ANSI codes from logs so they're readable in CI log viewers

> 💬 **Say:** "TF_VAR_ injects secrets, TF_CLI_ARGS_ sets default flags per subcommand, TF_INPUT=false prevents the pipeline from hanging waiting for input that will never come."

---

# 🎤 Interview Q&A — Lock Flags and -detailed-exitcode

**Q: When would you use `-lock=false` and is it ever safe?**

Almost never. The only safe case: you are the only person with access to the workspace AND you are doing a read-only inspection (not apply or destroy). Even then, `-lock-timeout=5m` is the better option — it waits for the lock to release instead of bypassing it entirely.

**`-lock-timeout` use case:** Two pipelines can collide (e.g., a hotfix and a regular deploy running simultaneously). With `-lock-timeout=3m`, the second pipeline waits up to 3 minutes for the first to finish — then proceeds safely instead of failing immediately.

---

**Q: What does `-detailed-exitcode` do and why is it useful?**

- Adds a third exit code: `0` = success + no changes, `1` = error, `2` = success + changes pending
- Without it, both "no changes" and "changes detected" return exit code 0 — indistinguishable in a script
- With it, a CI pipeline can skip the apply step when there's nothing to change (exit 0) and only run apply when changes are detected (exit 2)
- Saves deployment time and reduces risk — don't trigger an apply for a no-op plan

> 💬 **Say:** "-detailed-exitcode gives you three outcomes instead of two — your CI can skip apply for no-op plans, which is both faster and safer."

---
