# Amazon Managed Grafana (AMG)

> Fully managed Grafana service — no servers to run, no upgrades to manage, built-in AWS SSO/SAML authentication, and native IAM auth to AWS data sources.

## What AMG Handles For You

| Concern | Self-managed Grafana | AMG |
|---------|---------------------|-----|
| Infrastructure | You provision EC2/K8s | AWS managed |
| Upgrades | Manual | Automatic |
| Authentication | Configure LDAP/OAuth | AWS SSO / SAML built-in |
| AWS data source auth | IAM credentials in config | IAM role auth, no credentials |
| HA / scaling | You build | AWS handles |
| Plugins | Install manually | Curated set, enterprise included |

## Workspaces

A workspace is the unit of deployment — each workspace gets its own Grafana URL:

```bash
# Create a workspace
aws grafana create-workspace \
  --account-access-type CURRENT_ACCOUNT \
  --authentication-providers AWS_SSO \
  --workspace-name my-prod-grafana \
  --workspace-role-arn arn:aws:iam::123:role/AMGWorkspaceRole

# Returns: workspaceId, endpoint (https://g-xxx.grafana-workspace.us-east-1.amazonaws.com)
```

## Authentication

AMG supports:

| Method | Best for |
|--------|----------|
| **AWS SSO** | AWS Organizations users |
| **SAML 2.0** | Okta, Azure AD, Ping Identity |
| **AWS IAM Identity Center** | Centralized access control |

Permission levels per workspace: **Admin**, **Editor**, **Viewer**

## Data Sources — IAM Auth (No Credentials)

AMG uses IAM roles to authenticate to AWS data sources — no access keys stored in Grafana:

**Supported AWS data sources:**
- Amazon Managed Prometheus (AMP) — PromQL
- Amazon CloudWatch — metrics, logs, alarms
- AWS X-Ray — traces
- Amazon Elasticsearch / OpenSearch
- Amazon Timestream
- Amazon Athena
- Amazon Redshift

```bash
# Grant AMG workspace role access to AMP
aws iam attach-role-policy \
  --role-name AMGWorkspaceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess
```

In the AMG UI: add data source → select "Amazon Managed Service for Prometheus" → select workspace → no credentials needed.

## Pricing

- **$9/active editor per month**
- **$5/active viewer per month** (viewers free up to certain count depending on plan)
- Viewers who haven't logged in that month = not counted as active

## AMG vs Self-hosted Grafana

| Feature | AMG | Self-hosted Grafana |
|---------|-----|---------------------|
| Cost | Per user/month | EC2/EKS infra |
| AWS data source auth | IAM (no keys) | Keys or IRSA |
| Plugin support | Curated set | Any plugin |
| Multi-cloud sources | ✅ | ✅ |
| API / Terraform mgmt | ✅ | ✅ |
| Custom branding | ❌ | ✅ |
| On-premise data | VPC endpoints only | Direct |

**Choose AMG when:** AWS-focused shop, want zero ops, need SSO/SAML without config effort.

**Choose self-hosted when:** need custom plugins (Infinity, business charts), on-premise data sources, cost optimization at scale (thousands of users), or full dashboard-as-code control.

## Provisioning Dashboards in AMG

Use the Grafana HTTP API or Terraform:

```hcl
resource "aws_grafana_workspace" "this" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  name                     = "production"
}

resource "grafana_dashboard" "k8s_overview" {
  config_json = file("dashboards/k8s-overview.json")
  folder      = grafana_folder.k8s.id
}
```

## Common Interview Questions

**Q: How does AMG authenticate to AWS data sources?**
AMG's workspace IAM role is granted permissions to AWS services (e.g., `AmazonPrometheusQueryAccess`, `CloudWatchReadOnlyAccess`). When you query AMP or CloudWatch in Grafana, AMG assumes this role — no access keys stored in Grafana configuration.

**Q: AMG vs self-hosted Grafana on EKS — cost comparison?**
AMG: $9/editor/month — predictable, includes all Grafana Enterprise features. Self-hosted on EKS: 2-3 pods + EBS + ops time. For small teams (< 10 editors), AMG is often cheaper and definitely simpler. For large orgs (100+ editors), self-hosted becomes more cost-effective.

**Q: What's the trade-off of AMG's curated plugin set?**
AMG doesn't support all community plugins — only a vetted subset (Prometheus, Loki, Tempo, CloudWatch, X-Ray, business panels). If you need the Infinity datasource, Zabbix plugin, or custom-built plugins, you must self-host.

**Q: Can you manage AMG dashboards as code?**
Yes — AMG supports the standard Grafana HTTP API. Use Terraform's `grafana` provider or Grizzly CLI to provision dashboards, folders, and data sources from JSON files stored in Git. This gives you GitOps for your dashboards even on the managed service.
