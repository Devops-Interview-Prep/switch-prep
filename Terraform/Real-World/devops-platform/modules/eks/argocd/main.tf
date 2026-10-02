resource "helm_release" "this" {
  name             = var.release_name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  wait    = true
  timeout = 1800

  values = [
    yamlencode({
      global = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      server = {
        service = {
          type = var.server_service_type
        }
      }

      configs = {
        params = {
          "server.insecure" = var.server_insecure
        }
      }
    })
  ]
}