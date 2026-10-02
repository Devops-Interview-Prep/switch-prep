data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket       = var.remote_state_bucket
    key          = var.network_state_key
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

module "eks_core" {
  source = "../../../../stacks/new-environment/02-eks-core"

  client       = var.client
  environment  = var.environment
  name_prefix  = var.name_prefix
  cluster_name = var.cluster_name

  cluster_version              = var.cluster_version
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  cluster_subnet_ids           = data.terraform_remote_state.network.outputs.eks_subnet_ids
  node_subnet_ids              = data.terraform_remote_state.network.outputs.eks_subnet_ids

  cluster_security_group_ids = [
    data.terraform_remote_state.network.outputs.eks_cluster_security_group_id
  ]

  node_security_group_ids = [
    data.terraform_remote_state.network.outputs.eks_nodes_security_group_id
  ]

  attach_cni_policy_to_node_role = var.attach_cni_policy_to_node_role

  cluster_admin_principal_arns  = var.cluster_admin_principal_arns
  platform_admin_principal_arns = var.platform_admin_principal_arns
  developer_principal_arns      = var.developer_principal_arns
  developer_namespaces          = var.developer_namespaces
  viewer_principal_arns         = var.viewer_principal_arns

  node_ami_type             = var.node_ami_type
  node_capacity_type        = var.node_capacity_type
  node_instance_types       = var.node_instance_types
  node_desired_size         = var.node_desired_size
  node_min_size             = var.node_min_size
  node_max_size             = var.node_max_size
  node_max_unavailable      = var.node_max_unavailable
  node_root_volume_size     = var.node_root_volume_size
  node_root_volume_type     = var.node_root_volume_type
  node_imds_hop_limit       = var.node_imds_hop_limit
  node_labels               = var.node_labels
  node_taints               = var.node_taints
  enabled_cluster_log_types = var.enabled_cluster_log_types
  eks_addons                = var.eks_addons
  tags                      = var.tags
}

