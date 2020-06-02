resource "kubernetes_daemonset" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "monitoring"
  }
  spec {
    selector {
      match_labels = {
        k8s-app = "node-exporter"
      }
    }

    template {
      metadata {
        name = "node-exporter"
        labels = {
          k8s-app = "node-exporter"
        }
      }

      spec {
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }

        container {
          name  = "node-exporter"
          image = "prom/node-exporter"

          port {
            container_port = 9100
            host_port      = 9100
            name           = "scrape"
          }
        }

        host_pid     = true
        host_network = true
      }
    }
  }
}

resource "kubernetes_service" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "monitoring"
    annotations = {
      "prometheus.io/scrape" = "true"
    }
    labels = {
      k8s-app = "node-exporter"
    }
  }
  spec {
    cluster_ip = "None"
    port {
      name     = "scrape"
      port     = 9100
      protocol = "TCP"
    }

    selector = {
      k8s-app = "node-exporter"
    }
  }
}
