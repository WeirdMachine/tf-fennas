resource "kubernetes_endpoints" "glusterfs_cluster" {
  metadata {
    name      = "glusterfs-cluster"
    namespace = var.namespace
  }

  subset {
    address {
      ip = "192.168.2.10"
    }
    port {
      port = 1
    }
    address {
      ip = "192.168.2.11"
    }
    port {
      port = 1
    }
    address {
      ip = "192.168.2.12"
    }
    port {
      port = 1
    }
  }
}

resource "kubernetes_service" "glusterfs_cluster" {
  metadata {
    name      = "glusterfs-cluster"
    namespace = var.namespace
  }
  spec {
    port {
      port = 1
    }
  }
}
