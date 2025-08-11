resource "helm_release" "setup" {
  name        = "setup"
  namespace   = "default"
  chart       = "${path.module}/helm/setup"
  description = "Helm Chart to deploy cluster pre-requisites"
  version     = "0.0.1"

  values = [
    yamlencode({
      irsa_id       = azurerm_kubernetes_cluster.vwh_aks_cluster.key_vault_secrets_provider[0].secret_identity[0].client_id
      keyvault_name = azurerm_key_vault.wvh-aks-kv.name
      tenant_id     = data.azurerm_client_config.current.tenant_id
    })
  ]

  depends_on = [null_resource.aks_auth]
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "frontend"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.0"

  values = [
    file("${path.module}/helm/nginx/nginx-values.yaml")
  ]

  depends_on = [helm_release.setup]
}

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.0.1"

  values = [
    file("${path.module}/helm/argo/argocd-values.yaml")
  ]

  depends_on = [helm_release.setup]
}

resource "helm_release" "argocd_apps" {
  name      = "argocd-app-of-apps"
  namespace = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"

  values = var.environment == "prod" ? [
    file("${path.module}/helm/argo/argocd-apps.yaml"),
    yamlencode({
      applications = {
        "software.app-of-apps" = {
          source = {
            targetRevision = "main"
          }
        }
      }
    })
    ] : [
    file("${path.module}/helm/argo/argocd-apps.yaml")
  ]

  depends_on = [helm_release.argocd]
}