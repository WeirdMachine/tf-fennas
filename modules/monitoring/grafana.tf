resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "grafana"
      }
    }

    template {
      metadata {
        name      = "grafana"
        namespace = "monitoring"
        labels = {
          k8s-app = "grafana"
        }
      }

      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:latest"

          env {
            name  = "GF_INSTALL_PLUGINS"
            value = "grafana-piechart-panel,devopsprodigy-kubegraf-app"
          }

          port {
            name           = "grafana"
            container_port = 3000
          }

          volume_mount {
            mount_path = "/var/lib/grafana"
            name       = "grafana-storage"
          }
        }

        volume {
          name = "grafana-storage"
          glusterfs {
            endpoints_name = "glusterfs-cluster"
            path           = "grafana"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "3000"
    }
  }

  spec {
    selector = {
      k8s-app = "grafana"
    }

    port {
      name = "grafana"
      port = 3000
    }
  }
}

resource "kubernetes_ingress" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
      //      "traefik.ingress.kubernetes.io/router.tls": "true"
    }
  }

  spec {
    rule {
      host = "grafana.kube.arda"
      http {
        path {
          path = "/"
          backend {
            service_name = "grafana"
            service_port = "3000"
          }
        }
      }
    }
  }
}