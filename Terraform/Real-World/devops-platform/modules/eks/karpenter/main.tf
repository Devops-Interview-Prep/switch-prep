resource "helm_release" "karpenter" {
  name             = var.release_name
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = var.controller_role_arn
        }
      }

      settings = {
        clusterName     = var.cluster_name
        clusterEndpoint = var.cluster_endpoint
        //eksControlPlane = true
      }

      replicas = var.replicas


    })
  ]
}

resource "aws_eks_access_entry" "karpenter_node_role" {
  count = var.create_node_role_access_entry ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = var.node_role_arn
  type          = "EC2_LINUX"

  depends_on = [
    helm_release.karpenter
  ]
}

locals {
  ec2nodeclasses_yaml = templatefile("${path.module}/templates/ec2nodeclasses.yaml.tpl", {
    client_name    = var.client_name
    cluster_name   = var.cluster_name
    node_role_name = var.node_role_name
    ami_alias      = var.ami_alias
  })

  nodepools_yaml = templatefile("${path.module}/templates/nodepools.yaml.tpl", {
    client_name = var.client_name
  })

  ec2nodeclass_documents = {
    for index, manifest in compact(split("---", local.ec2nodeclasses_yaml)) :
    index => trimspace(manifest)
    if trimspace(manifest) != ""
  }

  nodepool_documents = {
    for index, manifest in compact(split("---", local.nodepools_yaml)) :
    index => trimspace(manifest)
    if trimspace(manifest) != ""
  }
}

resource "kubectl_manifest" "ec2nodeclasses" {
  for_each = local.ec2nodeclass_documents

  yaml_body = each.value

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "nodepools" {
  for_each = local.nodepool_documents

  yaml_body = each.value

  depends_on = [
    kubectl_manifest.ec2nodeclasses
  ]
}