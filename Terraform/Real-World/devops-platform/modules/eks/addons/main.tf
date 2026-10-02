resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name = var.cluster_name
  addon_name   = each.key

  addon_version               = try(each.value.addon_version, null)
  service_account_role_arn    = try(each.value.service_account_role_arn, null)
  configuration_values        = try(each.value.configuration_values, null)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}"
  })
}