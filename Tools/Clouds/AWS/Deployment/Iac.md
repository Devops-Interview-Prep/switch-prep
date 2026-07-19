# Infrastructure as Code on AWS

## Options Overview

| Tool | Type | Language | State management |
|------|------|----------|-----------------|
| **CloudFormation** | AWS native | YAML/JSON | AWS manages (stacks) |
| **CDK** | Generates CF | Python/TS/Java/Go | AWS manages (CloudFormation) |
| **Terraform** | Multi-cloud | HCL | Terraform state file (S3+DynamoDB) |
| **SAM** | CF extension | YAML + CF syntax | AWS manages |
| **Pulumi** | Multi-cloud | Python/TS/Go | Pulumi state (or S3) |

---

## AWS CloudFormation

### Template Anatomy

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "My app infrastructure"

Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, staging, prod]
    Default: dev

Conditions:
  IsProd: !Equals [!Ref Environment, prod]

Mappings:
  InstanceSizes:
    dev:
      instance: t3.small
    prod:
      instance: m5.large

Resources:
  # Required section — at least one resource
  MyBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain    # don't delete on stack delete
    Properties:
      BucketName: !Sub "my-app-${Environment}-${AWS::AccountId}"
      VersioningConfiguration:
        Status: !If [IsProd, Enabled, Suspended]

  MyDB:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceClass: !FindInMap [InstanceSizes, !Ref Environment, instance]
      Engine: mysql

Outputs:
  BucketName:
    Value: !Ref MyBucket
    Export:
      Name: !Sub "${AWS::StackName}-BucketName"
```

### Stack Lifecycle

```bash
# Create
aws cloudformation create-stack \
  --stack-name my-app-prod \
  --template-body file://template.yaml \
  --parameters ParameterKey=Environment,ParameterValue=prod \
  --capabilities CAPABILITY_IAM

# Preview changes before applying (safe)
aws cloudformation create-change-set \
  --stack-name my-app-prod \
  --change-set-name my-changes \
  --template-body file://template.yaml
aws cloudformation describe-change-set --change-set-name my-changes --stack-name my-app-prod
aws cloudformation execute-change-set --change-set-name my-changes --stack-name my-app-prod

# Drift detection (find manual changes)
aws cloudformation detect-stack-drift --stack-name my-app-prod
```

### Stack Policies — Protect Critical Resources

```json
{
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": ["Update:Replace", "Update:Delete"],
      "Resource": "LogicalResourceId/MyDB"
    }
  ]
}
```

Prevents accidental replacement/deletion of production databases during stack updates.

### StackSets — Multi-Account/Region

Deploy the same stack across all accounts in an AWS Organization:

```bash
aws cloudformation create-stack-set \
  --stack-set-name enable-cloudtrail \
  --template-body file://cloudtrail.yaml \
  --permission-model SERVICE_MANAGED \
  --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false

# Deploy to all accounts in an OU
aws cloudformation create-stack-instances \
  --stack-set-name enable-cloudtrail \
  --deployment-targets OrganizationalUnitIds=ou-abc123 \
  --regions us-east-1 eu-west-1
```

---

## AWS CDK — Cloud Development Kit

Generate CloudFormation from real programming languages. No more YAML for complex logic.

### CDK Construct Levels

| Level | Description | Example |
|-------|-------------|---------|
| **L1** | Direct CloudFormation resource (1:1 mapping) | `CfnBucket` |
| **L2** | Higher-level with sensible defaults | `s3.Bucket` |
| **L3** | Patterns (complete solutions) | `ecs_patterns.ApplicationLoadBalancedFargateService` |

```python
# Python CDK — EKS cluster with managed node group
from aws_cdk import Stack
from aws_cdk import aws_eks as eks
from constructs import Construct

class EksStack(Stack):
    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        cluster = eks.Cluster(self, "ProdCluster",
            version=eks.KubernetesVersion.V1_29,
            default_capacity=0    # manage node groups separately
        )

        cluster.add_nodegroup_capacity("AppNodes",
            instance_types=[ec2.InstanceType("m5.xlarge")],
            min_size=2,
            max_size=10,
            disk_size=100
        )

        # CDK handles IAM role creation, security groups, etc.
```

```bash
cdk synth    # generate CloudFormation
cdk diff     # preview changes (like change sets)
cdk deploy   # deploy
cdk destroy  # tear down
```

---

## Terraform on AWS

### Remote Backend (S3 + DynamoDB state lock)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
    dynamodb_table = "terraform-state-lock"  # prevents concurrent applies
  }
}
```

### Key AWS Resources

```hcl
# EKS cluster
resource "aws_eks_cluster" "prod" {
  name     = "prod-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = module.vpc.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
  }
}

# RDS with multi-AZ
resource "aws_db_instance" "prod" {
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.m5.large"
  multi_az               = true
  storage_encrypted      = true
  deletion_protection    = true
  skip_final_snapshot    = false
}
```

### CloudFormation vs Terraform

| Feature | CloudFormation | Terraform |
|---------|---------------|-----------|
| Multi-cloud | ❌ AWS only | ✅ |
| State management | AWS-managed | Terraform state (S3+DynamoDB) |
| Drift detection | ✅ Built-in | `terraform plan` |
| Language | YAML/JSON (verbose) | HCL (cleaner) |
| Import | Limited | `terraform import` |
| Rollback | Automatic on failure | Manual (re-run previous version) |
| Community | AWS docs | Terraform Registry (modules) |

### Handling Secrets in IaC

```hcl
# DON'T: hardcode secrets in Terraform
resource "aws_db_instance" "db" {
  password = "DO_NOT_DO_THIS"  # exposed in state file!
}

# DO: reference Secrets Manager (won't be in state in plaintext)
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "/prod/db-password"
}

resource "aws_db_instance" "db" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

## Common Interview Questions

**Q: CloudFormation vs Terraform — when to choose?**
CloudFormation when: AWS-only shop, want managed state (no S3 bucket to maintain), need StackSets for multi-account, or team isn't familiar with HCL. Terraform when: multi-cloud, cleaner syntax, better module ecosystem (Terraform Registry), need to import existing resources more easily, or prefer open-source tooling.

**Q: How do you manage Terraform state in a team?**
Remote backend in S3 with DynamoDB state locking. Each environment gets its own state file (separate S3 key). Never use local state in production. Enable versioning on the S3 bucket (recover previous state). Use Terraform Cloud/Enterprise for teams needing run history, RBAC, and policy-as-code (Sentinel).

**Q: CDK vs raw CloudFormation?**
CDK for complex infrastructure with conditional logic, loops, reusable components — things that are painful in YAML. Raw CloudFormation for simple resources, when you want AWS-native tooling with no local dependencies, or for templates that non-developers will read. CDK compiles to CloudFormation — you get the best of both (cloud-native stack management + programming language power).

**Q: How do you handle CloudFormation stack failures?**
By default, CloudFormation rolls back on any resource creation/update failure. Use `--disable-rollback` during debugging to see which resource failed. Check stack events in console for the specific error. Use change sets to preview before applying. Set `DeletionPolicy: Retain` on critical resources so they're not deleted during rollback.
