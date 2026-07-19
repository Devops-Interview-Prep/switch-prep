# AWS Systems Manager Parameter Store

> Hierarchical key-value store for configuration data and secrets. Free for standard parameters — the go-to place for app config that doesn't need rotation.

## Parameter Types

| Type | Description | Max size |
|------|-------------|---------|
| **String** | Plain text | 4KB (standard) / 8KB (advanced) |
| **StringList** | Comma-separated values | 4KB / 8KB |
| **SecureString** | Encrypted with KMS CMK | 4KB / 8KB |

```bash
# Store plain config
aws ssm put-parameter \
  --name /prod/myapp/database-host \
  --value "db.cluster.us-east-1.rds.amazonaws.com" \
  --type String

# Store encrypted secret
aws ssm put-parameter \
  --name /prod/myapp/database-password \
  --value "supersecretpassword" \
  --type SecureString \
  --key-id alias/myapp-key

# Retrieve (with decryption)
aws ssm get-parameter \
  --name /prod/myapp/database-password \
  --with-decryption \
  --query Parameter.Value --output text
```

## Hierarchical Paths

Parameters are organized in paths (like a filesystem) — enables bulk retrieval and IAM scoping:

```
/prod/payment-service/db-host
/prod/payment-service/db-password
/prod/payment-service/api-key
/staging/payment-service/db-host
/prod/notification-service/smtp-host
```

```bash
# Get all parameters for a service in one API call
aws ssm get-parameters-by-path \
  --path /prod/payment-service \
  --with-decryption \
  --recursive
```

IAM policy scoped to a path:

```json
{
  "Effect": "Allow",
  "Action": ["ssm:GetParameter", "ssm:GetParametersByPath"],
  "Resource": "arn:aws:ssm:us-east-1:123:parameter/prod/payment-service/*"
}
```

## Standard vs Advanced Tier

| Feature | Standard | Advanced |
|---------|----------|---------|
| Cost | Free | $0.05/parameter/month |
| Size | 4KB | 8KB |
| Parameters | 10,000/region | 100,000/region |
| Parameter policies | ❌ | ✅ |
| Throughput | 40 transactions/sec | 1000/sec |

## Parameter Policies (Advanced Tier)

Auto-expire or notify on parameters:

```bash
aws ssm put-parameter \
  --name /prod/myapp/temp-token \
  --type SecureString \
  --value "tok_abc123" \
  --policies '[
    {
      "Type": "Expiration",
      "Version": "1.0",
      "Attributes": {"Timestamp": "2024-12-31T00:00:00.000Z"}
    },
    {
      "Type": "ExpirationNotification",
      "Version": "1.0",
      "Attributes": {"Before": "5", "Unit": "Days"}
    }
  ]'
```

## Parameter Store vs Secrets Manager

| Feature | Parameter Store | Secrets Manager |
|---------|----------------|-----------------|
| **Cost** | Free (Standard) | $0.40/secret/month |
| **Auto-rotation** | ❌ | ✅ (Lambda-based) |
| **Secret versioning** | Version IDs | CURRENT/PENDING/PREVIOUS labels |
| **Cross-account** | ✅ | ✅ |
| **SecureString** | ✅ (KMS) | Always encrypted |
| **Size** | 4KB standard / 8KB advanced | 65KB |
| **Use for** | App config, feature flags, non-rotating values | DB credentials, API keys needing rotation |

**Decision rule:** Does the secret need automatic rotation? → Secrets Manager. Everything else → Parameter Store.

## Accessing from EKS

**Option 1: External Secrets Operator (ESO)**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
spec:
  refreshInterval: 10m
  secretStoreRef:
    name: aws-ssm-parameterstore
    kind: ClusterSecretStore
  target:
    name: app-config-secret
  dataFrom:
    - extract:
        key: /prod/payment-service    # get ALL params under this path
```

**Option 2: Secrets Store CSI Driver (ASCP)**

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-config-spc
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "/prod/payment-service/db-host"
        objectType: ssmparameter
      - objectName: "/prod/payment-service/db-password"
        objectType: ssmparameter
```

## Accessing from Lambda

```python
import boto3
import json

ssm = boto3.client('ssm')

def get_config():
    response = ssm.get_parameters_by_path(
        Path='/prod/payment-service',
        WithDecryption=True,
        Recursive=True
    )
    return {p['Name'].split('/')[-1]: p['Value'] for p in response['Parameters']}
```

## Common Interview Questions

**Q: Standard vs Advanced tier — when to use Advanced?**
Advanced for: large parameters (>4KB), parameter policies (auto-expiration, notifications), or if you need >10,000 parameters in a region or >40 TPS throughput. For most apps, Standard tier is sufficient and free.

**Q: How do hierarchical paths help in multi-environment setups?**
Path-based IAM policies let you restrict EKS service accounts (via IRSA) to only their environment's parameters: `/prod/payment-service/*` for prod pods, `/staging/payment-service/*` for staging. No code changes needed to separate environments — just different parameter paths.

**Q: How does Parameter Store compare with Secrets Manager for cost?**
100 non-rotating configs in Parameter Store = $0/month. Same 100 in Secrets Manager = $40/month. For app configuration that doesn't change often and doesn't need rotation (DB hostnames, service URLs, feature flags), Parameter Store is the obvious choice. Use Secrets Manager only for secrets that benefit from automatic rotation.

**Q: Is SecureString in Parameter Store really secure?**
SecureString is encrypted with KMS before storage — yes, the data is secure at rest. However, it's not as opinionated as Secrets Manager about access control and rotation. You must explicitly configure KMS CMK rotation and IAM policies. Secrets Manager adds built-in rotation and per-secret resource policies on top of this.
