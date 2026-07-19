# 🎤 Advanced HCL Patterns
**10 Slides · Dynamic Blocks, Count/ForEach, Ellipsis, Types, Sensitive, Cycles, Moved**

---

# 🔴 Slide 1 · Scenario: Nested Dynamic Blocks

**🏗️ Setup**
> *You need a security group where ingress rules are driven entirely by a variable — different callers pass different rule sets.*

**❓ The Question**
How do you use dynamic blocks to generate variable-length ingress rules on a security group?

**🔍 Diagnosis**
1. Define a typed variable that captures all rule fields
2. Use `dynamic "ingress"` with `for_each` over the variable
3. Use `content {}` to map each field from the iterator
4. Keep static rules (like egress allow-all) as normal blocks

**✅ Fix**
```hcl
variable "sg_rules" {
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
}

resource "aws_security_group" "app" {
  dynamic "ingress" {
    for_each = var.sg_rules          # ← iterates over each rule object
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
    }
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}
```

**🛡️ Prevention**
- Use `optional()` with defaults to avoid null reference errors when callers omit fields
- Validate the variable if certain port ranges must be enforced

> ⚠️ **Never:** Use `count` inside a `dynamic` block — dynamic blocks iterate with `for_each` only

---

# 🔴 Slide 2 · Scenario: Conditional Resource Creation (the 0/1 Trick)

**🏗️ Setup**
> *A WAF web ACL association should only be created in production — not in staging or dev.*

**❓ The Question**
How do you conditionally create a resource based on the environment, and how do you safely reference it in outputs?

**🔍 Diagnosis**
1. Use `count = condition ? 1 : 0` on the resource
2. Access the resource with `[0]` index — guarded by the same condition in outputs
3. For `for_each`-based conditionals, use `toset([])` vs `toset(["key"])`

**✅ Fix**
```hcl
# Create WAF association only in production
resource "aws_wafv2_web_acl_association" "prod" {
  count        = var.environment == "prod" ? 1 : 0  # ← 1 creates it, 0 skips it
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main[0].arn
}

# Guard output with the same condition — [0] only accessed when count == 1
output "waf_acl_arn" {
  value = var.environment == "prod" ? aws_wafv2_web_acl_association.prod[0].id : null
}

# Cleaner alternative: one() function
output "waf_acl_arn_safe" {
  value = one(aws_wafv2_web_acl_association.prod)  # ← null if count==0, value if count==1
}
```

**🛡️ Prevention**
- Prefer `for_each` over `count` for all non-boolean conditionals — more stable when items change
- Use `one()` to safely extract a single item from a count-based resource

> ⚠️ **Never:** Use `count` to create multiple named instances — use `for_each` instead; count is sensitive to ordering changes

---

# 🔴 Slide 3 · Scenario: Complex `for_each` with the Ellipsis Operator

**🏗️ Setup**
> *You have a map of environments, each with multiple named subnets. You need to create all subnets across all environments as a flat set of resources.*

**❓ The Question**
How do you flatten a nested data structure into a single map for `for_each`? What does `...` do?

**🔍 Diagnosis**
1. Start with a nested structure: environments → subnets
2. Use nested `for` expressions to produce a list of maps
3. Use `merge(list...)` with the ellipsis operator to flatten into a single map
4. Feed the result to `for_each`

**✅ Fix**
```hcl
locals {
  all_subnets = merge([
    for env_name, env_config in var.environments : {
      for subnet_name, cidr in env_config.subnets :
        "${env_name}-${subnet_name}" => {   # ← composite key: "prod-public-a"
          environment = env_name
          cidr        = cidr
        }
    }
  ]...)  # ← ... spreads the list into merge() as separate arguments
}

resource "aws_subnet" "all" {
  for_each   = local.all_subnets           # ← keyed by "prod-public-a", etc.
  cidr_block = each.value.cidr
  tags       = { Name = each.key }
}
```

**🛡️ Prevention**
- Always use stable string composite keys for `for_each` maps
- Add a `validation` block to prevent key collisions

> ⚠️ **Never:** Use numeric indices as `for_each` keys — if keys change, Terraform destroys and recreates resources that just moved positions

---

# 🔴 Slide 4 · Scenario: Tricky Type System — null vs "" vs not set

**🏗️ Setup**
> *You have an optional database password variable. Sometimes it's null, sometimes an empty string, sometimes a real value. Resources behave differently with each.*

**❓ The Question**
What is the difference between `null`, `""`, and an unset variable in Terraform?

**✅ Fix**
```hcl
variable "db_password" {
  type    = string
  default = null  # ← explicitly null means "not provided"
}

# coalesce(): return first non-null, non-empty value
locals {
  password = coalesce(var.db_password, data.aws_secretsmanager_secret_version.db.secret_string)
  # ← if db_password is null, falls back to Secrets Manager
}

# try(): return fallback if expression ERRORS (for optional map keys)
locals {
  instance_type = try(var.config["instance_type"], "t3.medium")
  has_type      = can(var.config["instance_type"])  # ← true/false, no error
}

# optional() in object types (Terraform 1.3+)
variable "config" {
  type = object({
    name          = string
    instance_type = optional(string, "t3.medium")  # ← default if caller omits it
    tags          = optional(map(string), {})
  })
}
```

**🛡️ Prevention**
- Always declare `sensitive = true` on password variables to prevent logging
- Use `optional()` in object types instead of checking for null throughout the code

> ⚠️ **Never:** Use `try()` around resource attribute references — attribute errors should be loud and fail the plan

---

# 🔴 Slide 5 · Scenario: Sensitive Values Propagate

**🏗️ Setup**
> *A variable is marked `sensitive = true`. You build a connection string from it. The output fails to plan with a sensitivity error.*

**❓ The Question**
How do sensitive values propagate through Terraform, and what do you do when an output depends on one?

**✅ Fix**
```hcl
variable "db_password" {
  type      = string
  sensitive = true  # ← redacted in plan/apply output
}

# Any expression referencing a sensitive value becomes sensitive
output "connection_string" {
  # ERROR without sensitive = true:
  # "Output refers to sensitive values"
  value     = "postgres://user:${var.db_password}@${aws_db_instance.main.endpoint}/db"
  sensitive = true  # ← required — propagates sensitivity to the output
}
```

**🛡️ Prevention**
- Encrypt state with KMS (`kms_key_id` in the S3 backend)
- Grant state bucket access only to CI roles and Terraform operators — not all engineers
- Consider `manage_master_user_password = true` for RDS — Terraform never sees the value

> ⚠️ **Never:** Assume `sensitive = true` protects the state file — values ARE still stored in state in plaintext; state encryption is a separate concern

---

# 🔴 Slide 6 · Scenario: Circular Dependencies

**🏗️ Setup**
> *A security group needs to allow traffic from itself (self-referencing). Adding the rule inside the resource block causes a circular dependency error.*

**❓ The Question**
How do you resolve a circular dependency in Terraform?

**🔍 Diagnosis**
1. Identify the cycle — usually `resource A → resource A` via self-referencing attribute
2. Split the circular reference out into a separate resource
3. The separate resource can reference the original without creating a cycle

**✅ Fix**
```hcl
# PROBLEM: can't reference self inside the same resource block
resource "aws_security_group" "app" {
  name = "app"
  # adding self-reference here creates a cycle
}

# SOLUTION: separate resource for the self-referencing rule
resource "aws_security_group_rule" "self_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id  # ← self-ref is safe here
  security_group_id        = aws_security_group.app.id
}
```

```bash
# Visualize the dependency graph to find the cycle
terraform graph | dot -Tpng > graph.png  # ← requires graphviz
```

**🛡️ Prevention**
- Prefer `aws_security_group_rule` over inline `ingress`/`egress` blocks for rules that reference other SGs
- Avoid inline rules on security groups that will be referenced by other security groups

> ⚠️ **Never:** Use `depends_on` to fix circular deps — it doesn't break the cycle, you must restructure the resources

---

# 🔴 Slide 7 · Scenario: Safe Refactoring with the `moved` Block

**🏗️ Setup**
> *You move a resource into a module. Without any guard, Terraform destroys the old resource and creates a new one — a data-loss risk for stateful resources.*

**❓ The Question**
How do you rename or move a Terraform resource without destroying and recreating it?

**✅ Fix**
```hcl
# Before refactoring: flat resource at root level
resource "aws_s3_bucket" "logs" { ... }

# After refactoring: same resource now lives inside a module
module "storage" { source = "./modules/storage" }
# Inside module: resource "aws_s3_bucket" "logs" { ... }

# WITHOUT moved block: Terraform sees a new address → destroys old, creates new
# WITH moved block: Terraform updates state address only — no infrastructure change
moved {
  from = aws_s3_bucket.logs                  # ← old address
  to   = module.storage.aws_s3_bucket.logs  # ← new address
}
```

```bash
# Verify: must show zero resource changes after adding the moved block
terraform plan
```

**🛡️ Prevention**
- Always add a `moved` block when renaming resources, changing `count` to `for_each`, or moving into modules
- Keep `moved` blocks for one full release cycle before removing them

> ⚠️ **Never:** Remove the `moved` block immediately after applying — teammates running older plans will lose the mapping

---

# 🎤 Slide 8 · Follow-up Q&A

---

### Q: What does the `...` (ellipsis) operator do in Terraform?
- It's the "expand" operator — converts a list/tuple into individual function arguments
- `merge(list_of_maps...)` spreads the list so each element is passed as a separate argument to `merge()`
- Without it, `merge` receives a single list argument and errors
- Identical to Python's `*args` unpacking

> 💬 **Say:** "The ellipsis turns a list into positional arguments — it's how you call a variadic function with a dynamically-sized list."

---

### Q: When would `try()` be dangerous?
- `try()` swallows errors — any expression that fails returns the fallback silently
- If you have a logic bug (wrong attribute name, wrong type), `try()` hides it
- Only use `try()` for genuinely optional values where a map key might not exist
- Never use `try()` around resource attribute references — those errors should fail loudly at plan time

> 💬 **Say:** "try() is a silent fallback — it hides bugs as well as it handles missing keys. Reserve it for optional map lookups only."

---

### Q: Can you use `for_each` and `count` on the same resource?
- No — they are mutually exclusive meta-arguments
- Mixing them in the same resource block causes a validation error at plan time
- If you think you need both, wrap the `for_each` resource in a module and apply `count` to the module call
- Typically, needing both is a design smell — reconsider the data structure

> 💬 **Say:** "count and for_each are mutually exclusive. If you think you need both, the real answer is to reshape the data."

---
