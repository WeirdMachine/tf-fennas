resource "kubernetes_namespace" "openfaas" {
  metadata {
    name = "openfaas"
  }
}

resource "kubernetes_namespace" "openfaas_fn" {
  metadata {
    name = "openfaas-fn"
  }
}


//TODO: remove nginx ingress annotion from openfaas-ingress
resource "helm_release" "openfaas" {
  name       = "openfaas"
  repository = "https://openfaas.github.io/faas-netes"
  chart      = "openfaas  "
  namespace  = "openfaas"

  set {
    name  = "generateBasicAuth"
    value = "true"
  }

  values = [
    file("${path.module}/files/values-armhf.yml")
  ]

}
