//provider "kubernetes-alpha" {
//  server_side_planning = true
//}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v0.15.1"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

}
