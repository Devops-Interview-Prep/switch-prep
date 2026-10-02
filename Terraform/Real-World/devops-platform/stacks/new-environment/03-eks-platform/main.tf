locals {
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : "${var.client}-${var.environment}"

  common_tags = merge(var.tags, {
    Client      = var.client
    Environment = var.environment
    ManagedBy   = "devops-launchpad"
    Stack       = "03-eks-platform"
  })
}
data "aws_partition" "current" {}
module "karpenter_iam" {
  source = "../../../modules/iam/karpenter"

  name_prefix          = local.name_prefix
  aws_region           = var.aws_region
  cluster_name         = var.cluster_name
  cluster_arn          = var.cluster_arn
  oidc_provider_arn    = var.oidc_provider_arn
  oidc_provider_url    = var.cluster_oidc_issuer_url
  namespace            = var.karpenter_namespace
  service_account_name = var.karpenter_service_account_name
  node_role_arn        = var.node_iam_role_arn

  tags = local.common_tags
}

module "karpenter" {
  source = "../../../modules/eks/karpenter"

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  client_name      = local.name_prefix

  namespace            = var.karpenter_namespace
  release_name         = var.karpenter_release_name
  chart_version        = var.karpenter_chart_version
  service_account_name = var.karpenter_service_account_name
  controller_role_arn  = module.karpenter_iam.controller_role_arn

  node_role_arn  = var.node_iam_role_arn
  node_role_name = var.node_iam_role_name

  ami_alias                     = var.karpenter_ami_alias
  replicas                      = var.karpenter_replicas
  controller_cpu_request        = var.karpenter_controller_cpu_request
  controller_memory_request     = var.karpenter_controller_memory_request
  controller_cpu_limit          = var.karpenter_controller_cpu_limit
  controller_memory_limit       = var.karpenter_controller_memory_limit
  create_node_role_access_entry = var.create_karpenter_node_role_access_entry

  depends_on = [
    module.karpenter_iam
  ]
}

module "aws_load_balancer_controller_iam" {
  source = "../../../modules/iam/aws-load-balancer-controller"

  name_prefix       = local.name_prefix
  cluster_name      = var.cluster_name
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.cluster_oidc_issuer_url

  namespace            = var.aws_load_balancer_controller_namespace
  service_account_name = var.aws_load_balancer_controller_service_account_name

  tags = local.common_tags
}

module "aws_load_balancer_controller" {
  source = "../../../modules/eks/aws-load-balancer-controller"

  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  vpc_id       = var.vpc_id

  namespace            = var.aws_load_balancer_controller_namespace
  release_name         = var.aws_load_balancer_controller_release_name
  chart_version        = var.aws_load_balancer_controller_chart_version
  service_account_name = var.aws_load_balancer_controller_service_account_name

  service_account_role_arn = module.aws_load_balancer_controller_iam.role_arn
  replica_count            = var.aws_load_balancer_controller_replica_count
  node_selector            = var.aws_load_balancer_controller_node_selector
  tolerations              = var.aws_load_balancer_controller_tolerations

  depends_on = [
    module.karpenter,
    module.aws_load_balancer_controller_iam
  ]
}

module "ebs_csi_irsa" {
  source = "../../../modules/iam/irsa-role"

  role_name    = "${local.name_prefix}-ebs-csi-driver-role"
  role_purpose = "ebs-csi-driver"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.cluster_oidc_issuer_url

  service_account_subjects = [
    "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  ]

  condition_operator = "StringEquals"

  managed_policy_arns = [
    var.ebs_csi_policy_arn != null && var.ebs_csi_policy_arn != "" ? var.ebs_csi_policy_arn : "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
  ]

  tags = local.common_tags
}

module "efs_csi_irsa" {
  source = "../../../modules/iam/irsa-role"

  role_name    = "${local.name_prefix}-efs-csi-driver-role"
  role_purpose = "efs-csi-driver"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.cluster_oidc_issuer_url

  service_account_subjects = [
    "system:serviceaccount:kube-system:efs-csi-*"
  ]

  condition_operator = "StringLike"

  managed_policy_arns = [
    var.ebs_csi_policy_arn != null && var.ebs_csi_policy_arn != "" ? var.ebs_csi_policy_arn : "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
  ]

  tags = local.common_tags
}

module "storage_addons" {
  source = "../../../modules/eks/addons"

  cluster_name = var.cluster_name

  addons = {
    aws-ebs-csi-driver = {
      addon_version               = var.ebs_csi_addon_version
      service_account_role_arn    = module.ebs_csi_irsa.role_arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }

    aws-efs-csi-driver = {
      addon_version               = var.efs_csi_addon_version
      service_account_role_arn    = module.efs_csi_irsa.role_arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  tags = local.common_tags

  depends_on = [
    module.ebs_csi_irsa,
    module.efs_csi_irsa
  ]
}

module "argocd" {
  source = "../../../modules/eks/argocd"

  release_name        = var.argocd_release_name
  namespace           = var.argocd_namespace
  chart_version       = var.argocd_chart_version
  server_service_type = var.argocd_server_service_type
  server_insecure     = var.argocd_server_insecure
  node_selector       = var.argocd_node_selector
  tolerations         = var.argocd_tolerations

  depends_on = [
    module.karpenter,
    module.storage_addons
  ]
}