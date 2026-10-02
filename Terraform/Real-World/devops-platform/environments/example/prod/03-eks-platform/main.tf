data "terraform_remote_state" "eks_core" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = var.eks_core_state_key
    region  = var.aws_region
    encrypt = true
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = var.network_state_key
    region  = var.aws_region
    encrypt = true
  }
}

module "eks_platform" {
  source = "../../../../stacks/new-environment/03-eks-platform"

  aws_region  = var.aws_region
  client      = var.client
  environment = var.environment
  name_prefix = var.name_prefix

  cluster_name            = data.terraform_remote_state.eks_core.outputs.cluster_name
  cluster_arn             = data.terraform_remote_state.eks_core.outputs.cluster_arn
  cluster_endpoint        = data.terraform_remote_state.eks_core.outputs.cluster_endpoint
  cluster_oidc_issuer_url = data.terraform_remote_state.eks_core.outputs.cluster_oidc_issuer_url
  oidc_provider_arn       = data.terraform_remote_state.eks_core.outputs.oidc_provider_arn

  node_iam_role_arn  = data.terraform_remote_state.eks_core.outputs.node_iam_role_arn
  node_iam_role_name = data.terraform_remote_state.eks_core.outputs.node_iam_role_name

  karpenter_namespace            = var.karpenter_namespace
  karpenter_release_name         = var.karpenter_release_name
  karpenter_chart_version        = var.karpenter_chart_version
  karpenter_service_account_name = var.karpenter_service_account_name
  karpenter_ami_alias            = var.karpenter_ami_alias
  karpenter_replicas             = var.karpenter_replicas

  create_karpenter_node_role_access_entry = var.create_karpenter_node_role_access_entry
  karpenter_controller_cpu_request        = var.karpenter_controller_cpu_request
  karpenter_controller_memory_request     = var.karpenter_controller_memory_request
  karpenter_controller_cpu_limit          = var.karpenter_controller_cpu_limit
  karpenter_controller_memory_limit       = var.karpenter_controller_memory_limit
  tags                                    = var.tags
  vpc_id                                  = data.terraform_remote_state.network.outputs.vpc_id

  aws_load_balancer_controller_namespace            = var.aws_load_balancer_controller_namespace
  aws_load_balancer_controller_release_name         = var.aws_load_balancer_controller_release_name
  aws_load_balancer_controller_chart_version        = var.aws_load_balancer_controller_chart_version
  aws_load_balancer_controller_service_account_name = var.aws_load_balancer_controller_service_account_name
  aws_load_balancer_controller_replica_count        = var.aws_load_balancer_controller_replica_count
  aws_load_balancer_controller_node_selector        = var.aws_load_balancer_controller_node_selector
  aws_load_balancer_controller_tolerations          = var.aws_load_balancer_controller_tolerations

  ebs_csi_policy_arn    = var.ebs_csi_policy_arn
  efs_csi_policy_arn    = var.efs_csi_policy_arn
  ebs_csi_addon_version = var.ebs_csi_addon_version
  efs_csi_addon_version = var.efs_csi_addon_version

  argocd_release_name        = var.argocd_release_name
  argocd_namespace           = var.argocd_namespace
  argocd_chart_version       = var.argocd_chart_version
  argocd_server_service_type = var.argocd_server_service_type
  argocd_server_insecure     = var.argocd_server_insecure
  argocd_node_selector       = var.argocd_node_selector
  argocd_tolerations         = var.argocd_tolerations
}