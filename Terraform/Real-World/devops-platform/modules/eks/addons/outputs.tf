output "addon_names" {
  description = "EKS managed add-on names."
  value       = keys(aws_eks_addon.this)
}

output "addon_arns" {
  description = "EKS managed add-on ARNs."
  value = {
    for name, addon in aws_eks_addon.this : name => addon.arn
  }
}