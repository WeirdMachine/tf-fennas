resource "kubernetes_config_map" "blackbox_exporter" {
  metadata {
    name      = "blackbox-exporter"
    namespace = "monitoring"
    labels = {
      k8s-app = "blackbox-exporter"
    }
  }

  data = {
    "config.yml" = file("${path.module}/files/balckbox_exporter.yml")
  }
}

resource "kubernetes_service" "blackbox_exporter" {
  metadata {
    name      = "blackbox-exporter"
    namespace = "monitoring"
    labels = {
      k8s-app = "blackbox-exporter"
    }
  }
  spec {
    port {
      port = 9115
    }

    selector = {
      k8s-app = "blackbox-exporter"
    }
  }
}

resource "kubernetes_deployment" "blackbox_exporter" {
  metadata {
    name      = "blackbox-exporter"
    namespace = "monitoring"
    labels = {
      k8s-app = "blackbox-exporter"
    }
  }
  spec {
    selector {
      match_labels = {
        k8s-app = "blackbox-exporter"
      }
    }

    template {
      metadata {
        name      = "blackbox-exporter"
        namespace = "monitoring"
        labels = {
          k8s-app = "blackbox-exporter"
        }
      }

      spec {
        container {
          name  = "blackbox-exporter"
          image = "prom/blackbox-exporter"

          port {
            container_port = 9115
          }

          volume_mount {
            mount_path = "/etc/blackbox_exporter"
            name       = "blackbox-exporter"
          }
        }

        volume {
          name = "blackbox-exporter"
          config_map {
            name = "blackbox-exporter"
          }
        }
      }
    }
  }
}
