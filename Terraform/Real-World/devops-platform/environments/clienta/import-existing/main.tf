terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "example"
}

locals {
  project      = "clienta-deployment"
  environment  = "clienta-deployment"
  cluster_name = "clienta-deployment-eks"
  vpc_name     = "CLIENTA-Deployment-VPC"
  oidc_host    = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED0C1234567890ABCDEF123456"
  tgw_id       = "tgw-3b24f2a8ca3d31ceb"

  common_tags = {
    ManagedBy   = "terraform"
    Project     = local.project
    Environment = local.environment
    VPC         = local.vpc_name
  }
}

# ──────────────────────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = local.vpc_name })
}

# ──────────────────────────────────────────────────────────────
# Subnets
# ──────────────────────────────────────────────────────────────

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.0.0/26"
  availability_zone = "us-east-1a"
  tags = merge(local.common_tags, {
    Name                                           = "CLIENTA-Deployment-VPC-public-1"
    Tier                                           = "public"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/clienta-deployment-eks" = "shared"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.0.64/26"
  availability_zone = "us-east-1b"
  tags = merge(local.common_tags, {
    Name                                           = "CLIENTA-Deployment-VPC-public-2"
    Tier                                           = "public"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/clienta-deployment-eks" = "shared"
  })
}

resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.16.0/20"
  availability_zone = "us-east-1a"
  tags = merge(local.common_tags, {
    Name                                           = "CLIENTA-Deployment-VPC-private-app-1"
    Tier                                           = "private-app"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/clienta-deployment-eks" = "shared"
    "karpenter.sh/discovery"                       = local.cluster_name
  })
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.32.0/20"
  availability_zone = "us-east-1b"
  tags = merge(local.common_tags, {
    Name                                           = "CLIENTA-Deployment-VPC-private-app-2"
    Tier                                           = "private-app"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/clienta-deployment-eks" = "shared"
    "karpenter.sh/discovery"                       = local.cluster_name
  })
}

resource "aws_subnet" "private_app_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.48.0/20"
  availability_zone = "us-east-1c"
  tags = merge(local.common_tags, {
    Name                                           = "CLIENTA-Deployment-VPC-private-app-3"
    Tier                                           = "private-app"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/clienta-deployment-eks" = "shared"
    "karpenter.sh/discovery"                       = local.cluster_name
  })
}

resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.80.0/24"
  availability_zone = "us-east-1a"
  tags              = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-db-1", Tier = "private-db" })
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.81.0/24"
  availability_zone = "us-east-1b"
  tags              = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-db-2", Tier = "private-db" })
}

resource "aws_subnet" "private_db_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.82.0/24"
  availability_zone = "us-east-1c"
  tags              = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-db-3", Tier = "private-db" })
}

# ──────────────────────────────────────────────────────────────
# Internet Gateway
# ──────────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-igw" })
}

# ──────────────────────────────────────────────────────────────
# Elastic IPs + NAT Gateways  (2 NATs: AZ-a and AZ-b)
# AZ-c private-app subnet routes through NAT-2 (AZ-b)
# ──────────────────────────────────────────────────────────────

resource "aws_eip" "nat_1" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-nat-eip-1" })
}

resource "aws_eip" "nat_2" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-nat-eip-2" })
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
  tags          = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-nat-gw-1" })
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
  tags          = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-nat-gw-2" })
}

# ──────────────────────────────────────────────────────────────
# Route Tables
# ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  route {
    cidr_block         = "10.0.0.10/32"
    transit_gateway_id = local.tgw_id
  }
  route {
    cidr_block         = "10.0.0.11/32"
    transit_gateway_id = local.tgw_id
  }

  tags = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-public-rt" })
}

resource "aws_route_table" "private_app_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
  route {
    cidr_block         = "10.0.0.10/32"
    transit_gateway_id = local.tgw_id
  }
  route {
    cidr_block         = "10.0.0.11/32"
    transit_gateway_id = local.tgw_id
  }

  tags = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-app-rt-1" })
}

resource "aws_route_table" "private_app_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
  route {
    cidr_block         = "10.0.0.10/32"
    transit_gateway_id = local.tgw_id
  }
  route {
    cidr_block         = "10.0.0.11/32"
    transit_gateway_id = local.tgw_id
  }

  tags = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-app-rt-2" })
}

resource "aws_route_table" "private_app_3" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
  route {
    cidr_block         = "10.0.0.10/32"
    transit_gateway_id = local.tgw_id
  }
  route {
    cidr_block         = "10.0.0.11/32"
    transit_gateway_id = local.tgw_id
  }

  tags = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-app-rt-3" })
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block         = "10.0.0.10/32"
    transit_gateway_id = local.tgw_id
  }
  route {
    cidr_block         = "10.0.0.11/32"
    transit_gateway_id = local.tgw_id
  }

  tags = merge(local.common_tags, { Name = "CLIENTA-Deployment-VPC-private-db-rt" })
}

# ──────────────────────────────────────────────────────────────
# Route Table Associations
# ──────────────────────────────────────────────────────────────

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_app_1.id
}

resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private_app_2.id
}

resource "aws_route_table_association" "private_app_3" {
  subnet_id      = aws_subnet.private_app_3.id
  route_table_id = aws_route_table.private_app_3.id
}

resource "aws_route_table_association" "private_db_1" {
  subnet_id      = aws_subnet.private_db_1.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_2" {
  subnet_id      = aws_subnet.private_db_2.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_3" {
  subnet_id      = aws_subnet.private_db_3.id
  route_table_id = aws_route_table.private_db.id
}

# ──────────────────────────────────────────────────────────────
# Security Groups
# Rules are managed by EKS/Karpenter — lifecycle ignore keeps
# terraform plan clean without destroying existing rules.
# ──────────────────────────────────────────────────────────────

resource "aws_security_group" "cluster" {
  name        = "clienta-deployment-eks-cluster-sg"
  description = "EKS cluster control plane security group - clienta-deployment-eks"
  vpc_id      = aws_vpc.main.id

  lifecycle { ignore_changes = [ingress, egress] }

  tags = merge(local.common_tags, { Name = "clienta-deployment-eks-cluster-sg" })
}

resource "aws_security_group" "node" {
  name        = "clienta-deployment-eks-node-sg"
  description = "EKS worker node security group - clienta-deployment-eks"
  vpc_id      = aws_vpc.main.id

  lifecycle { ignore_changes = [ingress, egress] }

  tags = merge(local.common_tags, {
    Name                                           = "clienta-deployment-eks-node-sg"
    "karpenter.sh/discovery"                       = local.cluster_name
    "kubernetes.io/cluster/clienta-deployment-eks" = "owned"
  })
}

resource "aws_security_group" "database" {
  name        = "clienta-deployment-database-sg"
  description = "Database security group - allows access only from EKS nodes"
  vpc_id      = aws_vpc.main.id

  lifecycle { ignore_changes = [ingress, egress] }

  tags = merge(local.common_tags, { Name = "clienta-deployment-database-sg" })
}

# ──────────────────────────────────────────────────────────────
# IAM — OIDC Identity Provider
# ──────────────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "main" {
  url             = "https://${local.oidc_host}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["06b25927c42a721631c1efd9431e648fa62e1e39"]

  tags = merge(local.common_tags, { Name = "clienta-deployment-eks-oidc-provider" })
}

# ──────────────────────────────────────────────────────────────
# IAM — EKS Cluster Role
# ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "cluster" {
  name = "clienta-deployment-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_eks" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ──────────────────────────────────────────────────────────────
# IAM — EKS Node Role
# ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "node" {
  name = "clienta-deployment-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ebs" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ──────────────────────────────────────────────────────────────
# IAM — Karpenter Controller Role (IRSA)
# ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "karpenter" {
  name = "clienta-deployment-eks-karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.main.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:karpenter"
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:aws:iam::123456789012:policy/clienta-deployment-eks-karpenter-controller-policy"
}

# ──────────────────────────────────────────────────────────────
# IAM — ALB Controller Role (IRSA)
# Shared with KEDA operator service account
# ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "alb_controller" {
  name = "clienta-deployment-eks-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.main.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_host}:sub" = [
            "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "system:serviceaccount:keda:keda-operator",
          ]
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::123456789012:policy/clienta-deployment-eks-aws-load-balancer-controller-policy"
}

# ──────────────────────────────────────────────────────────────
# IAM — EBS CSI Role (IRSA)
# ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "ebs_csi" {
  name = "clienta-deployment-eks-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.main.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ──────────────────────────────────────────────────────────────
# EKS Cluster
# ──────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = "1.35"
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids              = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id, aws_subnet.private_app_3.id]
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ──────────────────────────────────────────────────────────────
# EKS Node Group
# ──────────────────────────────────────────────────────────────

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "clienta-deployment-eks-ng-01"
  node_role_arn   = aws_iam_role.node.arn
  ami_type        = "AL2023_x86_64_STANDARD"
  disk_size       = 50
  instance_types  = ["t3.medium"]

  subnet_ids = [
    aws_subnet.private_app_1.id,
    aws_subnet.private_app_2.id,
    aws_subnet.private_app_3.id,
  ]

  scaling_config {
    min_size     = 1
    max_size     = 6
    desired_size = 2
  }

  tags = local.common_tags
}

# ──────────────────────────────────────────────────────────────
# EKS Add-ons
# ──────────────────────────────────────────────────────────────

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  addon_version = "v1.20.5-eksbuild.1"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = "v1.33.10-eksbuild.2"
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = "v1.12.4-eksbuild.10"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.61.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
}

resource "aws_eks_addon" "efs_csi" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "aws-efs-csi-driver"
  addon_version = "v3.2.0-eksbuild.1"
}

# ──────────────────────────────────────────────────────────────
# SQS — Karpenter Interruption Queue
# ──────────────────────────────────────────────────────────────

resource "aws_sqs_queue" "karpenter_interruption" {
  name                       = "clienta-deployment-eks-karpenter-interruption-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 300

  tags = local.common_tags
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgeToSendMessages"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.karpenter_interruption.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = [
            "arn:aws:events:us-east-1:123456789012:rule/clienta-deployment-eks-karpenter-scheduled-change",
            "arn:aws:events:us-east-1:123456789012:rule/clienta-deployment-eks-karpenter-spot-interruption",
            "arn:aws:events:us-east-1:123456789012:rule/clienta-deployment-eks-karpenter-rebalance",
            "arn:aws:events:us-east-1:123456789012:rule/clienta-deployment-eks-karpenter-instance-state-change",
          ]
        }
      }
    }]
  })
}

# ──────────────────────────────────────────────────────────────
# EventBridge Rules — Karpenter interruption handling
# ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  name          = "clienta-deployment-eks-karpenter-spot-interruption"
  description   = "Capture EC2 Spot interruption warnings for Karpenter"
  event_pattern = jsonencode({ "detail-type" = ["EC2 Spot Instance Interruption Warning"], "source" = ["aws.ec2"] })
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "karpenter_rebalance" {
  name          = "clienta-deployment-eks-karpenter-rebalance"
  description   = "Capture EC2 instance rebalance recommendations for Karpenter"
  event_pattern = jsonencode({ "detail-type" = ["EC2 Instance Rebalance Recommendation"], "source" = ["aws.ec2"] })
}

resource "aws_cloudwatch_event_target" "karpenter_rebalance" {
  rule      = aws_cloudwatch_event_rule.karpenter_rebalance.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "karpenter_instance_state_change" {
  name          = "clienta-deployment-eks-karpenter-instance-state-change"
  description   = "Capture EC2 instance state change events for Karpenter"
  event_pattern = jsonencode({ "detail-type" = ["EC2 Instance State-change Notification"], "source" = ["aws.ec2"] })
}

resource "aws_cloudwatch_event_target" "karpenter_instance_state_change" {
  rule      = aws_cloudwatch_event_rule.karpenter_instance_state_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "karpenter_scheduled_change" {
  name          = "clienta-deployment-eks-karpenter-scheduled-change"
  description   = "Capture AWS Health scheduled change events for Karpenter"
  event_pattern = jsonencode({ "detail-type" = ["AWS Health Event"], "source" = ["aws.health"] })
}

resource "aws_cloudwatch_event_target" "karpenter_scheduled_change" {
  rule      = aws_cloudwatch_event_rule.karpenter_scheduled_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

# ──────────────────────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────────────────────

output "cluster_name" { value = aws_eks_cluster.main.name }
output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_ca_data" { value = aws_eks_cluster.main.certificate_authority[0].data }
output "vpc_id" { value = aws_vpc.main.id }
output "private_app_subnets" {
  value = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id, aws_subnet.private_app_3.id]
}
output "karpenter_role_arn" { value = aws_iam_role.karpenter.arn }
output "alb_controller_role_arn" { value = aws_iam_role.alb_controller.arn }
output "interruption_queue_name" { value = aws_sqs_queue.karpenter_interruption.name }
