resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

module "gluster" {
  source    = "../../modules/gluster"
  namespace = "monitoring"
}
