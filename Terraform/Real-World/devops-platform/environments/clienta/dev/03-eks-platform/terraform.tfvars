aws_region = "us-east-1"

remote_state_bucket = "example-tf-state-123456789012-us-east-1"
eks_core_state_key  = "launchpad/environments/clienta/dev/02-eks-core/terraform.tfstate"

client      = "clienta"
environment = "dev"
name_prefix = "clienta-dev"

cluster_name = "clienta-dev-eks"

karpenter_namespace            = "kube-system"
karpenter_release_name         = "karpenter"
karpenter_chart_version        = "1.13.0"
karpenter_service_account_name = "karpenter"
karpenter_ami_alias            = "al2023@latest"
karpenter_replicas             = 2

create_karpenter_node_role_access_entry = false
karpenter_controller_cpu_request        = "500m"
karpenter_controller_memory_request     = "512Mi"
karpenter_controller_cpu_limit          = "1"
karpenter_controller_memory_limit       = "1Gi"
tags = {
  Project   = "devops-launchpad"
  Owner     = "devops"
  Terraform = "true"
}


network_state_key = "launchpad/environments/clienta/dev/01-network/terraform.tfstate"

aws_load_balancer_controller_namespace            = "kube-system"
aws_load_balancer_controller_release_name         = "aws-load-balancer-controller"
aws_load_balancer_controller_chart_version        = "1.13.3"
aws_load_balancer_controller_service_account_name = "aws-load-balancer-controller"
aws_load_balancer_controller_replica_count        = 2

aws_load_balancer_controller_node_selector = {}

aws_load_balancer_controller_tolerations = []
ebs_csi_policy_arn                       = null
efs_csi_policy_arn                       = null
ebs_csi_addon_version                    = null
efs_csi_addon_version                    = null

argocd_release_name        = "argocd"
argocd_namespace           = "argocd"
argocd_chart_version       = "10.1.2"
argocd_server_service_type = "ClusterIP"
argocd_server_insecure     = false

argocd_node_selector = {}

argocd_tolerations = []