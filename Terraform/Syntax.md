# 🧩 Terraform Syntax — Complete Reference
**57 Slides · Variables → Data Sources → Loops → Meta-Arguments → Dynamic Blocks → Null Resource → Credentials**

---

# 🗂️ Variables & Outputs

---

# 1️⃣ What Are Input Variables?

Variables are the **public API** of your module — they let the same code work across environments.

```hcl
variable "environment" {
  type        = string       # ← type constraint catches mismatches early
  description = "Deployment environment name"
  default     = "dev"        # ← fallback if no value is supplied
}
```

> ✅ **Rule:** Always declare `type` — it catches mismatches early and documents intent.

> 💡 **Takeaway:** Variables accept values from CLI flags, tfvars files, or environment variables — the module code never hard-codes environment-specific values.

---

# 2️⃣ Variable Types: Primitives

Terraform supports `string`, `number`, and `bool` as primitive types, each with optional validation.

```hcl
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_count" {
  type    = number
  default = 3

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 20
    error_message = "Instance count must be between 1 and 20."
  }
}
```

> ✅ **Rule:** Validation runs before the plan executes — it stops bad values before any API calls are made.

---

# 3️⃣ Variable Types: Collections & Sensitive

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "tags" {
  type    = map(string)
  default = { Project = "my-app", Environment = "prod" }
}

variable "database_config" {
  type = object({
    instance_class = string
    storage_gb     = number
    multi_az       = bool
  })
  default = { instance_class = "db.t3.medium", storage_gb = 100, multi_az = true }
}

variable "db_password" {
  type      = string
  sensitive = true   # ← Terraform will never print this value in logs or output
}
```

> ⚠️ **Watch out:** `sensitive = true` only masks terminal output — the value is still stored in state in plain text. Protect your state file with encryption.

---

# 4️⃣ Output Variables

```hcl
output "instance_ip" {
  value       = aws_instance.example.public_ip
  description = "Public IP of the web instance"
}

# CLI usage:
#   terraform output instance_ip → 52.11.222.33

# Cross-module reference (parent module consuming a child module output):
module "network" { source = "./modules/network" }

resource "aws_security_group_rule" "example" {
  cidr_blocks = [module.network.vpc_cidr]
}
```

> ✅ **Rule:** `output` blocks expose values to parent modules and the CLI — wire resources together inside the same module using direct attribute references, not outputs.

---

# 5️⃣ tfvars Files

```hcl
# terraform.tfvars
project_id = "gcp-terraform-307119"
location   = "europe-central2"
```

```bash
terraform plan                                  # picks up terraform.tfvars automatically
terraform plan -var-file=terraform.tfvars       # explicit single file
terraform apply -var-file=myvars-1.tfvars \
                -var-file=myvars-2.tfvars       # multiple files; last one wins on conflicts
```

> ✅ **Rule:** `terraform.tfvars` and `*.auto.tfvars` are loaded automatically — any other filename requires `-var-file`.

> ⚠️ **Watch out:** `terraform init` does NOT accept `-var-file`. Variables are only consumed during `plan` and `apply`.

---

# 6️⃣ Variable Precedence (Highest → Lowest)

| Priority | Source | Example |
|----------|--------|---------|
| 1 (highest) | `-var` CLI flag | `-var="environment=prod"` |
| 2 | `-var-file` CLI flag | `-var-file=prod.tfvars` |
| 3 | `*.auto.tfvars` files | `prod.auto.tfvars` |
| 4 | `terraform.tfvars` | auto-loaded if present |
| 5 | `TF_VAR_name` env vars | `export TF_VAR_db_password=...` |
| 6 (lowest) | `default` in variable block | `default = "dev"` |

```bash
export TF_VAR_db_password="my-secret-password"         # env var; ideal for CI/CD
terraform apply -var="environment=prod"                 # one-off CLI override
terraform apply -var-file=environments/prod.tfvars      # env-specific bundle
```

> ✅ **Rule:** In CI/CD pipelines, use `TF_VAR_` environment variables — credentials never appear in command history or build logs.

---

# 7️⃣ Locals vs Variables — Comparison

| | `variable` | `local` |
|--|-----------|---------|
| Set by | Caller / environment | Within module only |
| Purpose | Input parameters | Computed / derived values |
| Overridable | Yes (tfvars, CLI) | No — internal only |
| Validation | Yes (`validation` block) | No |
| Use case | Expose configuration | DRY expressions, complex logic |

> 💡 **Takeaway:** If a caller should configure it → `variable`. If it's derived from other values and shouldn't be overridden → `local`.

---

# 8️⃣ Locals in Practice

```hcl
variable "project"     { default = "myapp" }
variable "environment" { default = "prod" }

locals {
  name_prefix   = "${var.project}-${var.environment}"
  common_tags   = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  is_production = var.environment == "prod"
  instance_type = local.is_production ? "m5.xlarge" : "t3.medium"
}

resource "aws_instance" "web" {
  instance_type = local.instance_type
  tags          = merge(local.common_tags, { Name = "${local.name_prefix}-web" })
}
```

> ✅ **Rule:** If a value should be configurable by the caller → `variable`. If it's derived or internal → `local`.

> ⚠️ **Watch out:** Locals cannot have validation blocks — put constraints on the input `variable`, not on the local that consumes it.

---

# 9️⃣ Variables · Interview Q&A

**Q: What is the variable precedence order — which wins?**
- `-var` CLI flag wins over everything; then `-var-file`, then `*.auto.tfvars`, then `terraform.tfvars`
- Then `TF_VAR_name` environment variables, then `default` (lowest)
- In CI/CD: use `TF_VAR_` env vars so secrets never appear in logs

**Q: When do you use `locals` vs `variables`?**
- `variable` blocks are the public API — accept input from callers
- `local` values are private implementation details — computed expressions, DRY naming

**Q: How do you validate a Terraform variable?**
- Add a `validation` block inside the `variable` block; `condition` is a boolean
- Validation runs before the plan executes — catches bad input before any API calls

**Q: What does `sensitive = true` do?**
- Masks the value in all `plan`, `apply`, and `output` terminal output
- Does NOT encrypt the value in state — still stored in plain text
- To protect state: use remote backends with encryption (S3 + KMS)

> 💬 **Say:** "Sensitive masks output but not state — protect your state file separately."

---

# 🗂️ Data Sources

---

# 🎯 What Are Data Sources?

| Property | `data` block | `resource` block |
|---|---|---|
| Creates infrastructure? | No — reads existing | Yes — creates and manages |
| Tracked in state? | No (read-only) | Yes |
| Destroyed by `terraform destroy`? | No | Yes |
| Re-evaluated on every run? | Yes | Only when config changes |
| Ownership | Someone else owns it | Terraform owns it |

- Data sources fetch data from providers and make it available inside your config
- They are re-fetched on every `terraform plan` and `terraform apply`
- Use `filter` to narrow results; use `depends_on` when the target is created in the same config

> 💡 **Takeaway:** If you own it, use `resource`. If someone else owns it, use `data`.

---

# 🖼️ aws_ami — Latest AMI Lookup

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true          # ← get the newest matching AMI
  owners      = ["amazon"]   # ← only AMIs owned by Amazon

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id  # ← always latest, no hardcoding
  instance_type = "t3.micro"
}
```

- AMI IDs differ per region and become stale — never hardcode them
- `owners = ["amazon"]` prevents picking up community AMIs with the same name pattern

> ⚠️ Watch out: Pin to a specific AMI name pattern if you need fully reproducible builds — `most_recent` can shift between plan and apply.

---

# 🌐 aws_vpc + aws_subnets — Existing Network Lookup

```hcl
data "aws_vpc" "main" {
  tags = {
    Name = "production-vpc"  # ← look up by tag, not hardcoded VPC ID
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]  # ← chain: use VPC id from first data source
  }
  tags = {
    Tier = "private"
  }
}
```

- Chain data sources: output of one becomes input to another
- `aws_subnets` (plural) returns a list of IDs; `aws_subnet` (singular) errors if more than one matches

> ✅ Rule: Chain data sources to avoid hardcoding any IDs — VPC ID, subnet IDs, zone IDs should all come from lookups.

---

# 🌍 aws_route53_zone + Creating Records

```hcl
data "aws_route53_zone" "main" {
  name         = "company.com."   # ← trailing dot is required for Route53 zone names
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.company.com"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }
}
```

> ⚠️ Watch out: Include the trailing dot in the zone name (`"company.com."`) — without it, the lookup may fail or return unexpected results.

---

# 🔑 aws_iam_role + aws_secretsmanager_secret_version

```hcl
data "aws_iam_role" "eks_node_role" {
  name = "eks-node-instance-role"
}

resource "aws_eks_node_group" "workers" {
  node_role_arn = data.aws_iam_role.eks_node_role.arn
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/myapp/db_password"
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_password.secret_string
  )
}

resource "aws_db_instance" "postgres" {
  password = local.db_creds.password  # ← inject password without hardcoding
}
```

> ⚠️ Watch out: Secret values ARE stored in Terraform state. Use encrypted remote state (S3 + KMS) and restrict state file access.

---

# 🖥️ External Data Source — Run a Script

```hcl
data "external" "git_hash" {
  program = ["bash", "-c",
    "echo '{\"hash\": \"'$(git rev-parse --short HEAD)'\"}'"]
}

resource "aws_ssm_parameter" "deploy_version" {
  name  = "/app/deploy_version"
  value = data.external.git_hash.result["hash"]
  type  = "String"
}
```

The `external` data source program must:
- Read any inputs from stdin as JSON
- Output a **flat** `map(string)` as JSON to stdout (no nested objects)
- Exit with code `0` on success

> ⚠️ Watch out: External data sources run on every plan and apply. Avoid slow scripts or network calls — they block Terraform execution.

---

# 📊 Data vs Resource Comparison

| Question | `data` | `resource` |
|---|---|---|
| Who created it? | Another team / manually | Terraform |
| Destroyed on `terraform destroy`? | Never | Yes |
| Shows in state file? | No | Yes |
| Refreshed automatically? | Every plan/apply | Only on config change |
| Example: VPC you did not create | `data "aws_vpc"` | — |
| Example: VPC you want Terraform to manage | — | `resource "aws_vpc"` |

> ⚠️ Watch out: Using `resource` on something you do not own means `terraform destroy` will delete it — potentially catastrophic for shared infrastructure.

---

# 🎤 Data Sources · Interview Q&A

**Q: When do you use a data source instead of a resource?**
- Use `data` when the resource is managed outside Terraform: created manually, by another team, or in another state
- Using `resource` on something you do not own would cause Terraform to try to manage and potentially destroy it

**Q: How do data sources handle stale data between runs?**
- Data sources are refreshed on every `terraform plan` and `terraform apply` — always current
- Caveat: if external infra changes between plan and apply, the data source value seen during apply may differ from what the plan showed

> 💬 **Say:** "Data sources are always fresh — re-fetched every plan/apply — but plan and apply may see different values if infra changes in between."

---

# 🗂️ Loops

---

# 1️⃣ Loops with `count` (Basic)

`count` creates N copies of a resource using a numeric index starting at 0.

```hcl
variable "user_names" {
  type    = list(string)
  default = ["user1", "user2", "user3"]
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)       # ← number of copies to create
  name  = var.user_names[count.index]  # ← access element by numeric index
}

# Resources created:
# aws_iam_user.example[0] → "user1"
# aws_iam_user.example[1] → "user2"
# aws_iam_user.example[2] → "user3"
```

> ✅ **Rule:** Use `count` only when all copies are identical or differ only by position — numeric indices shift when items are added or removed from the middle.

---

# 2️⃣ `count` with Sets and Maps

```hcl
variable "my_set" {
  type    = set(string)
  default = ["value1", "value2", "value3"]
}

locals {
  my_list = tolist(var.my_set)  # ← set → ordered list (lexicographic order)
}

resource "my_resource" "from_set" {
  count = length(local.my_list)
  name  = local.my_list[count.index]
}
```

> ⚠️ **Watch out:** Using `count` over a map is fragile — prefer `for_each` with a map. If you find yourself converting a set or map just to use `count`, that's a signal to switch to `for_each`.

---

# 3️⃣ Loops with `for_each` (Basic)

`for_each` creates one resource per item in a `set(string)` or `map`, using a stable **string key** as the resource's identity.

```hcl
variable "user_names" {
  type    = set(string)
  default = ["user1", "user2", "user3"]
}

# Over a set — no conversion needed
resource "aws_iam_user" "from_set" {
  for_each = var.user_names  # ← each.key and each.value are both the string element
  name     = each.value
}

# Over a list — must convert to set first
resource "aws_iam_user" "from_list" {
  for_each = toset(var.user_names)   # ← toset() deduplicates and removes ordering
  name     = each.value
}

# Over a map — get both key and value
resource "aws_iam_user" "from_map" {
  for_each = var.my_map   # ← each.key = map key, each.value = map value
  name     = each.key
}
```

> ⚠️ **Watch out:** `toset()` silently drops duplicates — `["a", "a", "b"]` produces only two resources.

---

# 4️⃣ The count vs for_each Deletion Gotcha ⚠️

**This is the most important concept in Terraform loops.**

**count — index-based addressing:**
```
BEFORE ["a","b","c"]:          AFTER removing "b":
  resource[0] → "a"              resource[0] → "a"   ✅ unchanged
  resource[1] → "b"              resource[1] → "c"   ⚠️  DESTROY + RECREATE
  resource[2] → "c"              resource[2] → gone  ⚠️  DESTROY
```
**Removing 1 item triggered 2 destroy/recreate operations.**

**for_each — string-key addressing:**
```
BEFORE ["a","b","c"]:          AFTER removing "b":
  resource["a"] → "a"            resource["a"] → "a"  ✅ unchanged
  resource["b"] → "b"            resource["b"] → gone ✅ destroyed (only this one)
  resource["c"] → "c"            resource["c"] → "c"  ✅ unchanged
```
**Removing 1 item triggered exactly 1 destroy operation.**

> ⚠️ **Watch out:** Use `count` on a list of server names and someone removes a name from the middle — Terraform plans to destroy every server after the removed one.

---

# 5️⃣ count vs for_each — Decision Table

| Situation | Use | Example |
|-----------|-----|---------|
| N identical copies | `count` | 3 identical EC2 instances |
| Resources differ in one value | `for_each` with set | Multiple S3 buckets |
| Resources differ in multiple attributes | `for_each` with map | IAM users with different emails/roles |
| Input is a list of strings | `for_each = toset()` | Convert list → set |
| Need numeric index in a name | `count` | `name = "server-${count.index}"` |
| Must safely delete middle items | `for_each` | No cascade destruction |

> 💡 **Takeaway:** When in doubt, reach for `for_each` — it is safer by default. Only drop down to `count` when you genuinely need pure numeric replication.

---

# 6️⃣ `for` Expressions: List & Map Comprehensions

`for` expressions transform collections inside `locals` or `output` blocks — they produce new lists or maps, they do not create resources.

```hcl
variable "instance_ids" { default = ["i-001", "i-002", "i-003"] }

locals {
  # List comprehension — transform every element
  arn_list = [for id in var.instance_ids : "arn:aws:ec2:us-east-1:123:instance/${id}"]

  # Filter with if clause — keep only matching elements
  prod_ids = [for id in var.instance_ids : id if startswith(id, "i-00")]

  # Map comprehension — produce a map from a list
  id_map = { for id in var.instance_ids : id => "arn:aws:ec2:us-east-1:123:instance/${id}" }

  # Build a for_each-ready map from a list of objects
  sg_map = { for sg in var.security_groups : sg.name => sg }
}
```

> ✅ **Rule:** Square brackets `[for ...]` → list. Curly braces `{for ... : key => value}` → map. The `if` clause filters before producing output.

---

# 7️⃣ `for` Expressions: Iterating Maps

```hcl
variable "iam_users" {
  type = map(string)
  default = {
    user1 = "normal user"
    user2 = "admin user"
    user3 = "root user"
  }
}

output "user_with_roles" {
  value = [for name, role in var.iam_users : "${name} is the ${role}"]
}
# → ["user1 is the normal user", "user2 is the admin user", ...]

locals {
  my_list    = tolist(var.my_set)
  indexed_map = { for idx, value in local.my_list : idx => value }
}
```

> ✅ **Rule:** Use `for k, v in map` to get both key and value. Use `for v in map` to iterate values only.

---

# 8️⃣ `for_each` with Complex Maps (Objects)

```hcl
variable "users" {
  type = map(object({
    email = string
    role  = string
    teams = list(string)
  }))
  default = {
    alice = { email = "alice@example.com", role = "admin",  teams = ["platform", "sre"] }
    bob   = { email = "bob@example.com",   role = "viewer", teams = ["dev"] }
  }
}

resource "aws_iam_user" "user" {
  for_each = var.users
  name     = each.key
  tags     = {
    Email = each.value.email
    Role  = each.value.role
  }
}

resource "aws_iam_user_group_membership" "membership" {
  for_each = var.users
  user     = aws_iam_user.user[each.key].name  # ← cross-reference using the same key
  groups   = each.value.teams
}
```

> ✅ **Rule:** When two resources share the same `for_each` key space, use `resource[each.key]` to cross-reference them — this guarantees alignment without extra lookups.

---

# 9️⃣ Dynamic Lookup with `locals` + `setproduct` + `flatten`

```hcl
locals {
  instance_type = { prod = "m5.xlarge", staging = "t3.medium", dev = "t3.micro" }
  safe_type   = lookup(local.instance_type, var.environment, "t3.micro")  # ← returns default on miss
  strict_type = local.instance_type[var.environment]                       # ← errors on unknown key
}
```

```hcl
locals {
  roles = ["admin", "viewer", "editor"]
  envs  = ["prod", "staging"]
  pairs = setproduct(local.roles, local.envs)   # ← Cartesian product: 6 pairs

  role_env_map = {
    for pair in local.pairs : "${pair[0]}-${pair[1]}" => { role = pair[0], env = pair[1] }
  }
}
resource "aws_iam_policy" "env_policy" {
  for_each = local.role_env_map   # ← 6 policies: admin-prod, admin-staging, ...
  name     = "policy-${each.key}"
}
```

```hcl
locals {
  azs = flatten([
    for region, zones in var.regions : [
      for zone in zones : "${region}${zone}"
    ]
  ])
  # Without flatten: [["us-east-1a","us-east-1b"],["us-west-2a"]]
  # With flatten:    ["us-east-1a","us-east-1b","us-west-2a"]
}
```

> ✅ **Rule:** `lookup()` for safe fallback; direct `map[key]` for strict validation. Wrap any `for` inside a `for` with `flatten()`.

---

# 🔟 Loops · Interview Q&A

**Q: Why does `count` with a list cause unexpected resource recreation?**
- `count` uses list indices as resource addresses: `resource[0]`, `resource[1]`, `resource[2]`
- Remove the middle element → every element after it shifts down by one index
- `for_each` uses stable string keys — only the deleted key's resource is touched

> 💬 **Say:** "count uses index as identity — delete the middle and everything after shifts. for_each uses string keys — only the deleted key is destroyed."

**Q: How do you use `for_each` with a list?**
- Convert with `toset()`: `for_each = toset(var.names)` — sets de-duplicate and have no order
- If you need to convert a list of objects to a map: `for_each = { for obj in var.list : obj.key => obj }`

**Q: What is `flatten` and when do you need it?**
- `flatten` converts a list of lists into a single flat list: `[[1,2],[3]]` → `[1,2,3]`
- Needed when `for` expressions produce nested lists

**Q: When would you use `setproduct`?**
- When you need every combination of two or more sets — e.g., all roles × all environments
- Returns a list of lists: `[["admin","prod"], ["admin","staging"], ...]`

**Q: What is the difference between `lookup()` and direct map access?**
- `lookup(map, key, default)` returns the default if the key doesn't exist — never errors
- `map[key]` errors if the key is missing — catches typos in input variables at plan time

> 💡 **Takeaway:** Know the deletion gotcha cold — it is the single most common Terraform loop interview question.

---

# 🗂️ Meta-Arguments

---

# ⚙️ What Are Meta-Arguments?

| Meta-Argument | Purpose |
|---|---|
| `count` | Create N identical copies of a resource |
| `for_each` | Create named copies from a map or set |
| `depends_on` | Explicitly declare hidden dependencies |
| `provider` | Route a resource to an aliased provider |
| `lifecycle` | Control create / update / destroy behavior |
| `moved` | Rename a resource without destroying it |
| `removed` | Stop managing a resource without destroying it |

> 💡 **Takeaway:** Meta-arguments are special Terraform directives that control HOW resources behave — ordering, quantity, provider routing, and lifecycle rules.

---

# 🔗 depends_on — Hidden Dependencies

```hcl
# HIDDEN DEPENDENCY: Lambda needs the policy ATTACHED, not just the role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "handler" {
  function_name = "my-handler"
  role          = aws_iam_role.lambda.arn  # ← depends on ROLE, not ATTACHMENT

  depends_on = [aws_iam_role_policy_attachment.lambda_logs]  # ← force ordering
}

resource "aws_instance" "web" {
  subnet_id  = aws_subnet.public.id
  depends_on = [aws_internet_gateway.main]   # ← hidden dep: needs internet at boot
}
```

> ✅ Rule: Prefer attribute references for implicit deps. Use `depends_on` only for side effects not captured in attributes.

---

# 🔢 lifecycle: create_before_destroy

```hcl
resource "aws_db_instance" "main" {
  identifier     = "prod-db"
  engine         = "postgres"
  instance_class = "db.t3.medium"

  lifecycle {
    create_before_destroy = true  # ← create new first, then destroy old
    # WARNING: fixed names cause conflicts — two resources can't share one name
    # FIX: use random_id suffix or let AWS auto-generate the name
  }
}
```

- Terraform creates the new resource, updates all references, then destroys old
- Risk: **name conflicts** if the resource has a fixed name (e.g., S3 bucket)
- Risk: **temporary double cost** during the transition window

> 💡 **Takeaway:** `create_before_destroy` gives zero-downtime replacements — pair with random suffixes to avoid fixed-name conflicts.

---

# 🛡️ lifecycle: prevent_destroy + ignore_changes

```hcl
resource "aws_db_instance" "main" {
  identifier = "prod-db"

  lifecycle {
    prevent_destroy = true  # ← terraform destroy errors for this resource

    ignore_changes = [
      password,                    # ← rotated by Secrets Manager externally
      final_snapshot_identifier,
      tags["LastModified"],        # ← AWS adds this tag automatically
    ]
  }
}
```

- `prevent_destroy = true` causes `terraform destroy` and any plan showing a destroy to **error**
- `ignore_changes` tells Terraform to stop tracking specific fields

> ⚠️ Watch out: `prevent_destroy` only blocks Terraform destroys — it does not protect against AWS Console deletions or AWS CLI actions.

---

# 🔁 lifecycle: replace_triggered_by + precondition / postcondition

```hcl
resource "aws_autoscaling_group" "app" {
  lifecycle {
    # Terraform 1.2+: replace THIS resource when ANOTHER resource changes
    replace_triggered_by = [
      aws_launch_template.app.id,  # ← ASG replaced when launch template changes
    ]

    # Terraform 1.3+: validate BEFORE apply
    precondition {
      condition     = contains(["t3.medium", "m5.xlarge"], var.instance_type)
      error_message = "Only approved instance types allowed."
    }

    # Terraform 1.3+: validate AFTER apply succeeds
    postcondition {
      condition     = self.desired_capacity > 0
      error_message = "ASG desired capacity must be > 0 after apply."
    }
  }
}
```

> ✅ Rule: `replace_triggered_by` solves the "config changed but resource didn't" problem — the classic ASG + Launch Template pattern.

---

# 🌐 provider Meta-Argument — Aliased Providers

```hcl
provider "aws" {
  alias  = "north"
  region = "eu-north-1"
}

provider "aws" {
  region = "eu-central-1"  # ← default provider (no alias)
}

resource "aws_instance" "ec2_eu_north" {
  provider      = aws.north
  ami           = "ami-0ff338189efb7ed37"
  instance_type = "t3.micro"
}

# Passing aliased provider into a module
module "vpc_dr" {
  source    = "./modules/vpc"
  providers = { aws = aws.north }
}
```

> ✅ Rule: Always set `alias` on secondary provider blocks. Modules receive providers via the `providers` map argument, not the `provider` meta-argument.

---

# 📦 moved Block — Rename Without Destroying

```hcl
# RENAME RESOURCE WITHOUT RECREATION (Terraform 1.1+)
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.web
}

# Rename a for_each key without destroying the resource
moved {
  from = aws_iam_user.legacy["old-name"]
  to   = aws_iam_user.legacy["new-name"]
}
```

- Without `moved`: Terraform sees destroy (old name) + create (new name) = data loss risk
- With `moved`: Terraform updates the state address only — real resource untouched
- Remove the `moved` block after one successful apply

> ⚠️ Watch out: Without `moved`, rename = destroy + create. With `moved`, it is just a state address update.

---

# 🗑️ removed Block — Stop Managing Without Destroying

```hcl
# ORPHAN A RESOURCE FROM STATE WITHOUT DELETING IT (Terraform 1.7+)
removed {
  from = aws_instance.legacy

  lifecycle {
    destroy = false  # ← keep it running in AWS, just remove from state
  }
}
```

- Declarative: shows up in `terraform plan` output before any change is made
- Reviewable in pull requests — unlike `terraform state rm` which is imperative and untracked
- Omitting `lifecycle { destroy = false }` causes Terraform to destroy the real resource

> ✅ Rule: Use `removed` over `terraform state rm` — it is declarative, shows in plan, and is PR-reviewable.

---

# 🎤 Meta-Arguments · Interview Q&A

**Q: When would you use `create_before_destroy` and what is the risk?**
- Use for resources where downtime is unacceptable during replacement: RDS, ELB, ACM certs
- Risk: fixed-name resources cause creation to fail — old name still in use
- Fix: use `random_id` suffix or auto-generated names

**Q: What is the difference between `depends_on` and attribute references?**
- Attribute references create implicit deps — Terraform won't create the resource until the referenced one exists
- `depends_on` is for side effects not captured in attributes: IAM policy attachments, order-dependent API calls
- Overuse breaks parallelism — everything in the chain becomes sequential

**Q: What happens if you rename a resource without a `moved` block?**
- Terraform sees old name as destroy and new name as create — data loss for stateful resources
- Fix: add `moved` block before applying; remove it after one successful apply

> 💬 **Say:** "Attribute references are implicit and preferred. depends_on is for hidden side effects Terraform cannot see."

---

# 🗂️ Dynamic Blocks

---

# 🔄 What Problem Do Dynamic Blocks Solve?

Without dynamic blocks, repeated nested blocks must be copy-pasted manually:

```hcl
# WITHOUT dynamic — repeated copy-paste, hard to maintain
resource "aws_security_group" "main" {
  ingress { from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 22  to_port = 22  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
}
```

- Dynamic blocks are Terraform's `for` loop for **nested configuration blocks**
- They generate repeated sub-blocks from a list or map — no copy-pasting
- Work inside `resource`, `data`, `provider`, and `provisioner` blocks

> 💡 **Takeaway:** Dynamic blocks eliminate repeated nested block definitions — drive them from a variable list or map instead.

---

# 📐 Basic Dynamic Block — Security Group Ingress

```hcl
locals {
  ingress_rules = [
    { port = 443, description = "HTTPS" },
    { port = 80,  description = "HTTP" }
  ]
}

resource "aws_security_group" "main" {
  name   = "dynamic-sg"
  vpc_id = data.aws_vpc.main.id

  dynamic "ingress" {               # ← block type to repeat
    for_each = local.ingress_rules  # ← collection to iterate

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

> ✅ Rule: The label after `dynamic` must match the nested block type name exactly — `dynamic "ingress"` generates `ingress {}` blocks.

---

# 💾 Dynamic EBS Volumes

```hcl
variable "ebs_volumes" {
  type = list(object({
    device_name = string
    size        = number
    type        = string
  }))
  default = [
    { device_name = "/dev/sdb", size = 50,  type = "gp3" },
    { device_name = "/dev/sdc", size = 100, type = "gp3" }
  ]
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"

  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type
    }
  }
}
```

> ✅ Rule: Define the variable as `list(object({...}))` for structured iteration — each `value` gives you a typed object with named fields.

---

# 📜 Dynamic IAM Policy Statements

```hcl
variable "s3_buckets" {
  type    = list(string)
  default = ["bucket-a", "bucket-b", "bucket-c"]
}

data "aws_iam_policy_document" "s3_access" {
  dynamic "statement" {
    for_each = var.s3_buckets
    content {
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:PutObject"]
      resources = [
        "arn:aws:s3:::${statement.value}",
        "arn:aws:s3:::${statement.value}/*"
      ]
    }
  }
}
```

- When iterating a `list(string)`: use `<iterator>.value` to get the string
- When iterating a `map`: use `<iterator>.key` and `<iterator>.value`
- Dynamic blocks work inside data sources too, not just resources

> ✅ Rule: `aws_iam_policy_document` is the cleanest way to build IAM policies in Terraform — dynamic blocks make it driven entirely by variables.

---

# 🎛️ Conditional Block — The 0/1 Trick

```hcl
variable "enable_deletion_protection" { default = false }

resource "aws_db_instance" "main" {
  identifier = "my-database"

  dynamic "lifecycle" {
    for_each = var.enable_deletion_protection ? [1] : []  # ← [1] or []
    content {
      prevent_destroy = true
    }
  }
}

# MAP ITERATION: one tag {} block per map entry
resource "aws_instance" "web" {
  dynamic "tag" {
    for_each = var.tags_map   # ← map(string)
    content {
      key   = tag.key
      value = tag.value
    }
  }
}
```

> ✅ Rule: `for_each = condition ? [1] : []` is the idiomatic Terraform pattern for optional blocks — works anywhere a dynamic block is valid.

---

# 🏷️ iterator Label — Resolving Name Clashes

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  iterator = rule                   # ← rename from default "ingress" to "rule"

  content {
    from_port = rule.value.port     # ← use "rule" instead of "ingress"
    to_port   = rule.value.port
    protocol  = rule.value.protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

- Default iterator name is the same as the block label (`dynamic "ingress"` → `ingress.value`)
- Use `iterator` when nesting one dynamic block inside another to avoid collision

> ✅ Rule: Always use `iterator` when nesting dynamic blocks — the outer and inner labels would otherwise collide.

---

# 🎤 Dynamic Blocks · Interview Q&A

**Q: When should you use dynamic blocks vs `for_each` on resources?**
- `for_each` on a resource creates multiple separate, independently tracked resources in state
- `dynamic` inside a resource creates multiple nested blocks within ONE resource
- Use `dynamic` when the provider accepts repeated nested blocks within a single resource

**Q: How do you conditionally include a block using dynamic?**
- Use `for_each = condition ? [1] : []`
- True condition produces a one-element list → one block is generated
- False condition produces empty list → no block is generated

> 💬 **Say:** "for_each = multiple resources in state. dynamic = multiple blocks inside one resource. The [1] : [] trick makes any block optional."

---

# 🗂️ Null Resource & terraform_data

---

# ⚡ What Is null_resource and When to Use It?

`null_resource` is a fake resource with no cloud footprint — it creates nothing in AWS, GCP, or Azure. Its only purpose is to provide a hook for running commands at the right point in Terraform's dependency graph.

| Use Case | Why null_resource |
|---|---|
| Seed a database after it is created | Runs after `depends_on` is satisfied |
| SSH into an EC2 instance to configure it | `remote-exec` provisioner |
| Notify an external API after deployment | `local-exec` runs any shell command |
| Re-run a command when a value changes | `triggers` map controls re-execution |
| Coordinate side effects across resources | No single resource owns the action |

> 💡 **Takeaway:** null_resource is a placeholder that lets you attach provisioners and ordering to arbitrary points in your apply graph.

---

# 🗄️ null_resource local-exec — DB Seed Example

```hcl
resource "null_resource" "db_seed" {
  depends_on = [aws_db_instance.postgres]  # ← run AFTER DB is fully ready

  provisioner "local-exec" {
    command = "psql ${aws_db_instance.postgres.endpoint} -f seed.sql"
    environment = {
      PGPASSWORD = var.db_password
    }
  }

  triggers = {
    db_endpoint = aws_db_instance.postgres.endpoint  # ← re-run if endpoint changes
  }
}
```

- `local-exec` runs the command on the **machine running Terraform** (CI runner or laptop)
- `depends_on` is mandatory here — `null_resource` has no attributes to create implicit deps

> ✅ Rule: Always set `depends_on` on null_resource — it has no resource attributes to create implicit dependencies, so ordering must be explicit.

---

# 🖥️ null_resource remote-exec — SSH Provisioner

```hcl
resource "null_resource" "configure_app" {
  depends_on = [aws_instance.web]

  provisioner "remote-exec" {
    connection {
      host        = aws_instance.web.public_ip
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
    }

    inline = [
      "sudo yum update -y",
      "sudo systemctl start my-app"
    ]
  }
}
```

> ⚠️ Watch out: Provisioners are a last resort. Prefer `user_data` / `cloud-init` for instance bootstrap, or Ansible for ongoing configuration management.

---

# 🔁 triggers Map Mechanics

```hcl
resource "null_resource" "redeploy" {
  triggers = {
    image_tag  = var.docker_image_tag
    config_sha = sha256(file("config.json"))        # ← re-run if config file changes
  }

  provisioner "local-exec" {
    command = "kubectl set image deployment/app container=${var.docker_image_tag}"
  }
}
```

- Without `triggers`: provisioners run **only once** at creation time
- When any value in the `triggers` map changes: Terraform **destroys** the null_resource and **creates** a new one — re-running all provisioners
- `sha256(file("..."))` detects file content changes

> ⚠️ Watch out: Changing a trigger value causes a destroy + create, not an in-place update. This is by design.

---

# 🆚 null_resource vs terraform_data (Terraform 1.4+)

```hcl
resource "terraform_data" "db_seed" {
  depends_on = [aws_db_instance.postgres]
  input      = aws_db_instance.postgres.endpoint  # ← replaces the triggers map

  provisioner "local-exec" {
    command = "psql ${self.input} -f seed.sql"
  }
}
```

| | `null_resource` | `terraform_data` |
|---|---|---|
| Provider required? | Yes — `hashicorp/null` | No — built into Terraform core |
| Re-run mechanism | `triggers = {}` map | `input` argument |
| Terraform version | Any | 1.4+ |
| Recommended? | Legacy — still valid | Yes — preferred for new code |

> ✅ Rule: Use `terraform_data` for any new code on Terraform 1.4+. Use `null_resource` only when targeting older Terraform versions.

---

# 🎤 Null Resource · Interview Q&A

**Q: When should you use null_resource instead of a provisioner on the main resource?**
- Use `null_resource` when the action depends on multiple resources, not just one
- Use it when you need to re-run the action independently via `triggers`
- Use it when the script does not logically belong to any single resource

**Q: What is the triggers map and when would you use it?**
- When any value in the map changes, Terraform destroys and recreates the null_resource — re-running all provisioners
- Common uses: run DB migrations when a schema version changes, redeploy when a config file SHA256 changes
- `sha256(file("..."))` is the idiomatic way to track file content changes

> 💬 **Say:** "null_resource is for side effects that span resources or need independent re-run control via triggers. terraform_data is the modern replacement — no extra provider needed."

---

# 🗂️ Handling AWS Credentials

---

# 🚦 Three Approaches Ranked by Risk

| Rank | Approach | Risk Level | Use Case |
|---|---|---|---|
| Worst | Hardcoded in `.tf` file | Critical — leaks via git history | Never |
| Bad | Shared credentials file `~/.aws/credentials` | Medium — plaintext on disk | Local dev only |
| Acceptable | Environment variables | Medium — no git leak, but still static keys | CI/CD fallback |
| Best | IAM role / OIDC | None — no long-lived credentials | All cloud and CI |

> 💡 **Takeaway:** Never hardcode credentials. Use IAM roles in cloud environments, OIDC in CI/CD, and aws-vault locally.

---

# ⚠️ Hardcoded vs Environment Variables

```hcl
# ANTI-PATTERN: HARDCODED CREDENTIALS — LEAKS VIA GIT HISTORY FOREVER
provider "aws" {
  region     = "eu-central-1"
  access_key = "AKIATQ37NXB2HS7IVM5R"          # ← ends up in git history permanently
  secret_key = "MJy5JX6HIqHwP9gLAv+22kff..."   # ← fatal — rotate immediately if committed
}
```

```bash
# ACCEPTABLE: ENVIRONMENT VARIABLES — NO GIT LEAK, BUT STILL STATIC KEYS
export AWS_ACCESS_KEY_ID="AKIATQ37NXB2HS7IVM5R"
export AWS_SECRET_ACCESS_KEY="MJy5JX6HIqHwP9..."
export AWS_SESSION_TOKEN="..."   # if using temporary credentials

terraform plan  # Terraform picks these up automatically
```

> ⚠️ Watch out: Even if you delete them later, secrets in git history are recoverable. Rotate immediately if this happens.

---

# 📋 Credential Precedence Order

| Priority | Source | Notes |
|---|---|---|
| 1 (highest) | Static keys in provider block | Never use in production |
| 2 | Environment variables: `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | Checked next |
| 3 | Shared credentials file: `~/.aws/credentials` | Named profile support |
| 4 | EC2 / ECS instance metadata (IAM role on instance/task) | Best for cloud runners |
| 5 (lowest) | IAM role via SSO / OIDC | Best for CI/CD |

> ⚠️ Watch out: Debug credential issues by checking this order — an unexpected env var will silently override everything below it.

---

# 🏆 IAM Role Best Practice — No Static Credentials

```hcl
provider "aws" {
  region = "us-east-1"
  # Terraform automatically uses:
  #   - EC2 instance profile      (if running on EC2)
  #   - IRSA pod role             (if running on EKS with IRSA configured)
  #   - ECS task role             (if running in an ECS task)
  # No access_key or secret_key needed
}
```

- Credentials are temporary, automatically rotated, and scoped to the role's permissions
- No secrets to store, rotate, or accidentally leak

> ✅ Rule: This is the correct approach for any Terraform runner hosted in AWS — EC2, EKS, or ECS.

---

# 🔐 GitHub Actions OIDC — No Stored Secrets

```yaml
jobs:
  terraform:
    permissions:
      id-token: write   # ← required: allows GitHub to issue OIDC token
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/TerraformRole
          aws-region: us-east-1

      - run: terraform apply -auto-approve
```

- GitHub issues a JWT token; AWS validates it via the OIDC provider and returns temporary credentials
- Credentials are scoped to the job duration — no rotation needed ever

> ✅ Rule: OIDC is the gold standard for CI/CD — no secrets stored, no rotation, scoped to repo and branch.

---

# 📄 IAM Trust Policy for OIDC

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::123:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub":
        "repo:my-org/my-repo:ref:refs/heads/main"
    }
  }
}
```

- The `sub` condition locks this role to a **specific repo and branch**
- Without the `sub` condition, ANY GitHub Actions workflow in ANY repo could assume this role

> ⚠️ Watch out: Always scope the trust policy to your repo — omitting `sub` is a critical security misconfiguration.

---

# 🏢 assume_role Multi-Account Pattern + Anti-Patterns

```hcl
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::PROD_ACCOUNT_ID:role/TerraformDeployRole"
    session_name = "terraform-ci-prod"  # ← appears in CloudTrail for auditability
    duration     = "1h"
  }
}
```

**Anti-patterns:**

| Anti-pattern | Risk | Fix |
|---|---|---|
| Hardcoded keys in `.tf` | Leaked in git history — permanently | Use env vars or IAM role |
| Committing `.tfvars` with secrets | Anyone with repo access sees them | `.gitignore` + Secrets Manager |
| Long-lived access keys | Rotation is manual; keys leak over time | Switch to OIDC / IAM roles |
| Shared team keys | No auditability — who ran what? | Per-user roles or OIDC |

---

# 🎤 Credentials · Interview Q&A

**Q: How do you handle Terraform credentials in CI/CD securely?**
- Best practice: OIDC — no stored secrets anywhere
- GitHub Actions requests a short-lived JWT token → AWS validates via OIDC provider → issues temporary credentials
- Credentials live only for the job duration — no rotation needed
- Scoped to a specific repo and branch in the IAM trust policy `Condition` block

> 💬 **Say:** "OIDC means GitHub gets a token, not a key. AWS validates the token and issues temporary creds. No secret is ever stored."

**Q: How do you deploy to multiple AWS accounts with Terraform?**
- Use `assume_role` in the provider block
- The CI runner has one IAM role (in a central tools account) that can assume roles in target accounts
- Each target account has a `TerraformDeployRole` with required permissions and a trust policy allowing the CI role
- CloudTrail shows the assumed role and `session_name` for every API call — full auditability

> 💬 **Say:** "One CI role, assume_role per target account — no per-account credentials stored anywhere."

---
