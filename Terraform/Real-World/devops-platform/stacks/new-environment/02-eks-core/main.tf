locals {
  name_prefix  = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : "${var.client}-${var.environment}"
  cluster_name = var.cluster_name != null && var.cluster_name != "" ? var.cluster_name : "${local.name_prefix}-eks"

  common_tags = merge(var.tags, {
    Client      = var.client
    Environment = var.environment
    ManagedBy   = "devops-launchpad"
    Stack       = "02-eks-core"
  })
}

module "eks_roles" {
  source = "../../../modules/iam/eks-roles"

  name_prefix                    = local.name_prefix
  attach_cni_policy_to_node_role = var.attach_cni_policy_to_node_role

  tags = local.common_tags
}

module "eks_kms" {
  source = "../../../modules/security/kms"

  alias_name              = "${local.cluster_name}-secrets"
  description             = "KMS key for EKS secrets encryption for ${local.cluster_name}"
  deletion_window_in_days = var.kms_deletion_window_in_days

  tags = local.common_tags
}

module "eks_cluster" {
  source = "../../../modules/eks/cluster"

  cluster_name       = local.cluster_name
  cluster_version    = var.cluster_version
  cluster_role_arn   = module.eks_roles.cluster_role_arn
  subnet_ids         = var.cluster_subnet_ids
  security_group_ids = var.cluster_security_group_ids
  kms_key_arn        = module.eks_kms.key_arn

  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  enabled_cluster_log_types    = var.enabled_cluster_log_types

  cluster_admin_principal_arns  = var.cluster_admin_principal_arns
  platform_admin_principal_arns = var.platform_admin_principal_arns
  developer_principal_arns      = var.developer_principal_arns
  developer_namespaces          = var.developer_namespaces
  viewer_principal_arns         = var.viewer_principal_arns

  tags = local.common_tags

  depends_on = [
    module.eks_roles
  ]
}

module "system_node_group" {
  source = "../../../modules/eks/managed-node-group"

  cluster_name            = module.eks_cluster.cluster_name
  node_group_name         = "${local.cluster_name}-system"
  node_role_arn           = module.eks_roles.node_role_arn
  subnet_ids              = var.node_subnet_ids
  node_security_group_ids = var.node_security_group_ids

  ami_type        = var.node_ami_type
  capacity_type   = var.node_capacity_type
  instance_types  = var.node_instance_types
  desired_size    = var.node_desired_size
  min_size        = var.node_min_size
  max_size        = var.node_max_size
  max_unavailable = var.node_max_unavailable

  root_volume_size = var.node_root_volume_size
  root_volume_type = var.node_root_volume_type
  imds_hop_limit   = var.node_imds_hop_limit

  labels = merge(var.node_labels, {
    "nodepool"                           = "system"
    "workload-type"                      = "platform"
    "karpenter.sh/discovery"             = local.cluster_name
    "devops-launchpad.example.com/stack" = "02-eks-core"
  })

  taints = var.node_taints

  tags = merge(local.common_tags, {
    "karpenter.sh/discovery" = local.cluster_name
  })

  depends_on = [
    module.eks_roles,
    module.eks_cluster
  ]
}

module "eks_addons" {
  source = "../../../modules/eks/addons"

  cluster_name = module.eks_cluster.cluster_name
  addons       = var.eks_addons

  tags = local.common_tags

  depends_on = [
    module.eks_cluster,
    module.system_node_group
  ]
}