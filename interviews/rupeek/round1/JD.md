# Rupeek — Tech Lead DevOps · Job Description

> Reference copy of the JD and interview process, kept with the prep notes.

---

## About Rupeek

Rupeek, established in 2015 and headquartered in Bangalore, is India's leading asset-backed digital lending fintech platform, focused on monetising India's gold market through gold-backed loans across 40+ cities, with 5,00,000+ customers and partnerships with top banks and financial institutions. Investors include Sequoia Capital, Accel Partners, Bertelsmann and GGV Capital. Turned profitable in April 2024 and raised equity from Manipal Group and Elevation Capital.

## About the role

Rupeek's infrastructure spans RFPL and RCPL (customer-facing apps, lending core, ledger systems, operations) running on AWS with **EKS as the primary compute plane**. DevOps is a horizontal function serving all engineering pods and owns the interface with Infosec on audits, RBI/DPDP compliance evidence and incident response.

The Tech Lead - DevOps is the senior-most engineer in the team and its technical lead: sets standards, mentors the team, owns infrastructure vision.

- **Title:** Tech Lead - DevOps
- **Experience:** 5+ years
- **Location:** Bangalore

## Key responsibilities

- Senior-most DevOps engineer; technical lead for the DevOps team
- Sets vision and direction for infrastructure: cloud architecture, Kubernetes platform, CI/CD, observability, cost, reliability
- Owns IaC standards: Terraform module design, state management, drift detection, review process
- Owns the production readiness bar for every service that ships production traffic
- Partners with Infosec to pass audits (RBI IT Outsourcing, SOC 2, ISO 27001, DPDP) and due diligence (lender, investor, partner)
- Leads incident response from the infra side when the blast radius is large
- Mentors junior and mid DevOps engineers; runs design and code reviews
- Represents DevOps in architecture reviews for major product initiatives
- Sets AI-fluency standards for the team: tooling, prompt patterns, safe use of AI in production workflows
- Peer to senior SDE IIIs across product pods

## Must-have skills

**Cloud & Kubernetes**
- Deep AWS: VPC design, IAM, EKS, RDS/Aurora, S3, KMS, cost architecture, multi-AZ / multi-region trade-offs
- EKS operations: node group strategy, cluster upgrades, addons lifecycle, admission controllers, network policies, PSA
- Debugging at layers others can't: kernel/OS, container runtime, CNI, etcd, control plane

**Infrastructure as Code**
- Terraform mastery: module design, remote state, workspaces vs directories, provider version discipline, testing (terratest, tflint, checkov)
- Has designed and enforced IaC standards across a team: PR review process, plan/apply gating, drift detection
- Opinion on Terraform vs Pulumi vs CDK, and why

**CI/CD & SDLC**
- Production CI/CD with strong controls: immutable artifact tagging, signed artifacts (cosign), promotion gates, per-environment approvals
- Supply chain security: SLSA levels, SBOMs, dependency pinning, npm/PyPI incident response
- GitOps patterns

**Observability & Reliability**
- Prometheus, Grafana, Alertmanager, PagerDuty, from scrape config to SLO-driven alerting
- On-call rotations, runbooks, blameless post-mortems
- Distributed tracing (OpenTelemetry, Jaeger) and structured logging

**Security & Compliance**
- At least one major audit with Infosec (SOC 2, ISO 27001, RBI)
- Secrets management (Vault, Secrets Manager, KMS), workload identity (IRSA), least-privilege IAM
- Regulated-industry constraints: data localisation, PII handling, audit trails, evidence collection
- Real security incidents: DDoS, credential leaks, supply chain compromise

**Scripting & Automation**
- Strong Python or Go; production-quality automation
- Bash fluency and the Linux toolchain

**AI Fluency**
- Uses AI tools (Claude Code, Cursor) daily; opinions on where AI helps and hurts in the DevOps SDLC; can articulate "AI-safe" infra change management

**Leadership**
- Mentored junior and mid engineers; writes well (runbooks, RFCs, post-mortems); holds the production readiness line without becoming a bottleneck; pushes back on timelines when infra risk is real

## Persona

- Engineering degree in CS or related
- Has held a senior-most DevOps / SRE / Platform role before, where infra actually mattered
- Fintech, payments or regulated-industry background preferred
- Recent hands-on: Terraform and a cluster touched in the last month
- Comfortable as the 2am escalation point

## Interview process

**Recruiter screen & informational call** — motivation, comp, notice period, role context, two-way fit.

**Round 1 — Terraform, IaC, Kubernetes & AWS deep dive**
- Review a real Terraform module; probe module boundaries, state, drift, review process
- AWS + EKS architecture depth: VPC/IAM/EKS operations, upgrades, admission controllers
- Cost governance: past experience setting up cost guardrails and optimising cost

**Round 2 — Automation, incident response & infra design**
- Live scripting/automation exercise (Python or Go)
- Walk through a past production incident
- Design the infra for a new service end-to-end

**Round 3 — Security, compliance & role fit**
- Past audits and Infosec partnership
- Regulated-industry constraints
- Vision for infra
- Team, culture and role fit
