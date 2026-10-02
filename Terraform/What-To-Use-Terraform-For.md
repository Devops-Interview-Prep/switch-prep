# What Terraform can do vs what you should use it for

> Terraform has a provider for almost everything, which is exactly why a tech lead needs a written boundary. This note lists what Terraform *can* manage, what it is the *right* tool for given the alternatives on the market, and the decision rules to apply when someone proposes "let's just do it in Terraform". The real platform repo in [Real-World/devops-platform](Real-World/devops-platform/) is used as the example of where the line was drawn.

---

## The one-sentence rule

**Terraform owns things with a lifecycle that is created, rarely changed, and destroyed as a unit; it should not own things that change many times a day, that are configured *inside* a running system, or that another controller already reconciles.**

## What Terraform can do (the long list)

Cloud control-plane resources (compute, network, storage, databases, queues, IAM, KMS, DNS); Kubernetes objects (via `kubernetes`, `helm`, `kubectl` providers); SaaS configuration (Datadog monitors, PagerDuty schedules, GitHub repos and branch protection, Okta, Cloudflare, Grafana dashboards, Vault policies, Snowflake grants); VM bootstrap through `user_data` and `remote-exec`/`local-exec` provisioners; database users and grants (postgresql/mysql providers); TLS certificates (`tls`, ACM); random values; even running arbitrary scripts (`null_resource`, `external` data source). Capability is not the question. Fit is.

## The decision table

| Area | Can Terraform do it? | Should it? | Use instead / alongside | Why |
|---|---|---|---|---|
| **VPC, subnets, NAT, endpoints, TGW, security groups** | Yes | **Yes, always** | — | Rare change, high blast radius, plan diff is the control. `01-network` in the repo. |
| **IAM roles and policies, KMS keys, Organizations/SCPs, Identity Center** | Yes | **Yes** | Access Analyzer in CI for validation | Reviewable, auditable; access entries and IRSA roles in `02`/`03`. |
| **EKS control plane, managed node groups, EKS add-ons** | Yes | **Yes** | EKS Auto Mode if you want AWS to run add-ons | Cluster lifecycle is a Terraform shape. |
| **Cluster bootstrap add-ons that need AWS IAM** (Karpenter, LB controller, ESO, CSI drivers, ArgoCD itself) | Yes | **Yes, once, at bootstrap** | Then hand day-2 to ArgoCD (app-of-apps) | Terraform must create the IAM roles anyway; installing the Helm chart in the same stack avoids a manual step. `03-eks-platform` does exactly this. |
| **Karpenter NodePools, Kyverno policies, namespaces, quotas, network policies** | Yes (`kubectl_manifest`) | **Bootstrap only; day-2 in GitOps** | ArgoCD/Flux from a platform repo | They change often, reviewers are Kubernetes people, and `terraform destroy` with CRs and finalizers is painful. The repo applies NodePools from Terraform today; moving them to an ArgoCD platform app is the listed improvement. |
| **Application Deployments, Services, Ingress, HPA, ConfigMaps** | Yes | **No** | Helm charts + ArgoCD/Flux; Kustomize | Deploy frequency, rollback semantics, progressive delivery, developer ownership. The repo stops at ArgoCD for this reason. |
| **Helm releases of third-party apps** (Prometheus stack, ingress-nginx, cert-manager) | Yes (`helm_release`) | **Prefer GitOps** | ArgoCD Application pointing at the chart | Two sources of truth (Terraform state + Helm release secrets), slow plans, provider needs a live cluster token. Acceptable for the bootstrap set only. |
| **Secrets values** (DB passwords, API keys) | Yes (`random_password`, Secrets Manager resources) | **Avoid holding values** | RDS `manage_master_user_password`, Vault, Secrets Manager rotation, External Secrets Operator at runtime | Anything Terraform generates is in state and plan. Terraform may create the *secret container* and the IAM to read it. The repo's generated RDS passwords in state are the counter-example. |
| **Secret rotation** | Barely | **No** | Secrets Manager rotation Lambdas, Vault dynamic secrets | Rotation is a runtime loop, not a plan/apply. |
| **OS configuration inside VMs** (packages, users, files, services) | Yes (`user_data`, provisioners) | **Minimal bootstrap only** | Packer for the image, Ansible/SSM State Manager for config, cloud-init for first boot | Provisioners are not idempotent and leave no state; a golden AMI plus a tiny `user_data` (fetch secret, start service) is what the repo's `solr` and `ra` modules do. |
| **Machine images / AMIs** | No (only consume) | — | Packer, EC2 Image Builder | Terraform selects an AMI (`data "aws_ami"`, SSM alias); it should not build one. |
| **Container images** | No | — | CI (Docker buildx, Kaniko), ECR | Terraform creates the ECR repo and lifecycle policy (`modules/ecr`), never pushes images. |
| **Database schema and migrations** | Possible (provisioners, providers) | **No** | Flyway/Liquibase in a Helm pre-upgrade hook or CI job | Migrations are app-versioned and must run in deploy order. |
| **Database users, roles, grants** | Yes (postgresql/mysql providers) | **Sometimes** | App migrations, or Terraform if the DB is reachable from CI | Fine for bootstrap users; the provider needs network access to the DB from the runner, which is often the blocker. |
| **DNS records** | Yes | **Yes for infra records** (ALB aliases, validation records); **consider octoDNS/external-dns for app records** | `external-dns` creates records from Ingress annotations | `modules/route53` for platform aliases is right; per-service records are better created by the thing that owns the service. |
| **Observability config** (dashboards, monitors, alert rules, on-call schedules) | Yes (Datadog, Grafana, PagerDuty providers) | **Yes for the platform baseline; apps own theirs as code too** | Grafana-as-code (Grafonnet, dashboards in Git synced by the operator), Prometheus rules via GitOps | Alert rules next to the service they watch; schedules and escalation policies are platform-owned. |
| **CI/CD configuration** (GitHub/GitLab repos, branch protection, runners, Jenkins jobs) | Yes | **Yes for repos and protection; no for job definitions** | Jenkinsfiles / workflow YAML in the repo; JCasC for Jenkins | Branch protection is a compliance control and belongs in reviewable IaC; pipelines belong with the code. |
| **Serverless** (Lambda, API Gateway, Step Functions) | Yes | **Infra yes, code packaging no** | SAM, Serverless Framework, or CI builds the zip and Terraform references the artifact | Terraform is poor at build steps. |
| **ECS task definitions** | Yes | **Mixed** | Terraform for the service/cluster/IAM; task definition image tag updated by the deploy pipeline (`ignore_changes` on the task definition) | Deploy-frequency mismatch again. |
| **One-off operational tasks** (cleanups, data copies, orphan SG deletion) | Yes (import then destroy) | **Only when you need the audit trail** | A reviewed script, or `import` + `destroy` in a throwaway root | The repo's `_sg-cleanup` root did exactly this: import orphan SGs into a local-state root and destroy them. Acceptable; archive the root afterwards. |
| **Multi-cloud or SaaS glue** (Cloudflare, Okta, Atlassian, Snowflake) | Yes | **Yes, this is a strength** | — | One tool, one review process, one audit trail across vendors. |
| **Policy-as-code** (what is allowed in the cluster or account) | Partially | **No** | OPA/Conftest on plans, Kyverno/Gatekeeper in-cluster, SCPs (which Terraform *creates*) | Terraform creates the policy objects; the enforcement engine is something else. |
| **Cost controls** (budgets, anomaly detection) | Yes | **Yes** | Infracost on PRs for the delta | Guardrails are infrastructure. |

## Tools you will be compared against (know the one-line verdict)

| Tool | What it is | When it beats Terraform | When Terraform wins |
|---|---|---|---|
| **CloudFormation** | AWS-native declarative IaC with managed state and rollback | Pure-AWS shops that want no state to manage; StackSets across accounts; some day-zero features | Multi-vendor, readability, plan diff quality, module ecosystem, speed |
| **AWS CDK** | Imperative constructs that synthesise CloudFormation | Single-team AWS-native apps; developers who want L2/L3 abstractions | Horizontal platforms, auditors who read diffs, anything outside AWS |
| **Pulumi** | Real languages compiling to a declarative engine; can use Terraform providers | Developer-led teams, complex logic, unit tests in the language | Regulated review (declarative plan is the control), hiring, tooling depth |
| **OpenTofu** | MPL fork of Terraform | Licence concerns; built-in state encryption | Same tool; pick by ecosystem support (HCP vs Spacelift) |
| **Crossplane** | Kubernetes control plane that reconciles cloud resources from CRs | Platform teams exposing self-service claims to developers inside the cluster; continuous reconciliation | Bootstrapping the cluster Crossplane runs on; provider maturity; blast radius of a controller with cloud admin |
| **ACK (AWS Controllers for Kubernetes)** | Per-service Kubernetes controllers for AWS resources | App teams that want an SQS queue as a CR next to their Deployment | Everything shared or foundational |
| **Terragrunt** | Thin wrapper for DRY roots and dependencies | Many roots × environments; generated backends; `run-all` | Small estates; teams that find the indirection confusing |
| **Ansible** | Agentless config management | Configuring what is *inside* servers; orchestration steps; network devices | Creating cloud resources (Ansible can, but has no plan or state) |
| **Packer** | Image builder | Golden AMIs/containers for VM fleets | — (complementary) |
| **Helm** | Kubernetes package manager | Templating and releasing app manifests | Cloud resources |
| **ArgoCD / Flux** | GitOps reconcilers | Everything inside the cluster after bootstrap; drift correction every few minutes | Things needing cloud IAM or existing before the cluster |
| **Kustomize** | Overlay-based manifest customisation | Simple per-env patches without templating | — |
| **Atlantis / Spacelift / env0 / HCP Terraform** | Terraform automation and collaboration | Running Terraform with PR gating, policy, RBAC, drift detection | They *run* Terraform; not alternatives |

## Decision rules to say out loud

1. **If it has cloud IAM or a cloud API lifecycle, Terraform.** VPC, EKS, RDS, IAM, KMS, S3, SQS, DNS zones, budgets.
2. **If it lives inside Kubernetes and a GitOps engine is running, GitOps.** Terraform installs the engine and whatever the engine needs to start.
3. **If it changes with every deploy, the deploy pipeline owns it.** Image tags, task definitions, Lambda code, app config.
4. **If it is a secret value, Terraform may create the box, never the contents.** Managed passwords, Vault, ESO.
5. **If it configures the inside of a machine, Packer first, cloud-init second, Ansible/SSM third, provisioners never.**
6. **If it is a one-off, prefer a reviewed script unless you need the plan as evidence.** Then a throwaway root with `import` and `destroy`, archived afterwards.
7. **If another controller reconciles the field, add `ignore_changes` with a comment or stop managing the resource.** Autoscaler desired counts, EMR managed scaling, LB controller tags.
8. **If the review audience is auditors, prefer the tool whose diff they can read.** That is usually Terraform's plan.

## Where the real repo draws the line, and whether it is right

| Decision in `devops-platform` | Verdict |
|---|---|
| VPC/EKS/IAM/KMS/RDS/S3/SQS/ECR in Terraform | Right |
| Karpenter, LB controller, CSI, ArgoCD installed by Terraform in `03-eks-platform` | Right for bootstrap |
| Karpenter NodePools/EC2NodeClasses applied via `kubectl_manifest` from templates | Acceptable at bootstrap; move day-2 ownership to an ArgoCD platform app |
| ArgoCD repo secret created by Terraform | Acceptable (needs the credential at bootstrap); better via ESO from Secrets Manager |
| Application workloads in Helm-values repos reconciled by ArgoCD, not Terraform | Right |
| Solr/RA EC2 configured by `user_data` fetching `.env` from Secrets Manager | Right pattern; a Packer AMI would shorten boot and remove the apt/curl dependencies |
| RDS passwords generated by `random_password` | Wrong tool for the contents; switch to `manage_master_user_password` |
| Orphan security groups removed via an import-and-destroy root | Acceptable one-off; archive the root |
| Per-service DNS via `modules/route53` in the application stack | Fine; `external-dns` would remove the need per service |
| No Terraform-managed monitors or dashboards yet | Gap: add the platform baseline (Grafana/Datadog providers) with alert rules kept next to services via GitOps |

## Interview questions this note answers

- "Would you manage Kubernetes resources with Terraform?" Bootstrap yes, day-2 no, and here is the boundary.
- "Terraform or Ansible?" Different layers: Terraform creates, Ansible configures inside; prefer Packer to minimise what Ansible must do.
- "Why not Crossplane for everything?" Because something must create the cluster Crossplane runs on, and because provider maturity and controller blast radius matter in a regulated shop.
- "Should developers write Terraform?" For their service's cloud resources via a feature-flagged stack like `application-stack`, yes, with platform-owned modules and a plan policy; for the landing zone, no.
- "How do you keep secrets out of state?" Designs where Terraform never sees the value, plus ephemeral resources where it must pass through.
