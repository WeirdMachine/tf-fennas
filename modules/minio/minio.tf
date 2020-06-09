resource "kubernetes_service_account" "minio" {
  metadata {
    name      = "minio"
    namespace = var.namespace
  }
}


resource "kubernetes_secret" "minio" {
  metadata {
    name      = "minio"
    namespace = var.namespace
    labels = {
      k8s-app : "minio"
    }
  }
  type = "Opaque"
  data = {
    accesskey = var.minio_access_key
    secretkey = var.minio_secret_key
  }
}

resource "kubernetes_stateful_set" "minio" {
  metadata {
    name      = "minio"
    namespace = var.namespace
    labels = {
      k8s-app : "minio"
    }
  }

  spec {

    selector {
      match_labels = {
        k8s-app = "minio"
      }
    }
    service_name = "minio"

    template {

      metadata {
        name = "minio"
        labels = {
          k8s-app = "minio"
        }
      }
      spec {
        service_account_name = "minio"

        security_context {
          run_as_group = 1000
          run_as_user  = 1000
          fs_group     = 1000
        }

        container {
          name  = "minio"
          image = "registry.fanya.dev/minio-arm"

          command = [
            "/bin/sh",
            "-ce",
            "/usr/bin/docker-entrypoint.sh minio -S /etc/minio/certs/ server /export"
          ]

          volume_mount {
            name       = "export"
            mount_path = "/export"
          }

          port {
            name           = "http"
            container_port = 9000
          }

          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = "minio"
                key  = "accesskey"
              }
            }
          }

          env {
            name = "MINIO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = "minio"
                key  = "secretkey"
              }
            }
          }

          //Todo: jwt token auth
          env {
            name  = "MINIO_PROMETHEUS_AUTH_TYPE"
            value = "public"
          }

          liveness_probe {
            http_get {
              path   = "/minio/health/live"
              port   = "http"
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/minio/health/ready"
              port = "http"
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 3
          }

          resources {
            requests {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "export"
          glusterfs {
            endpoints_name = "glusterfs-cluster"
            path           = "minio"
          }
        }

      }
    }
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_service" "minio" {
  metadata {
    name      = "minio"
    namespace = var.namespace
    labels = {
      k8s-app = "minio"
    }
    annotations = {
      "prometheus.io/scrape" = true,
      "prometheus.io/path"   = "/minio/prometheus/metrics"
    }
  }

  spec {
    port {
      name        = "http"
      port        = 9000
      protocol    = "TCP"
      target_port = 9000
    }
    selector = {
      k8s-app = "minio"
    }

  }
}

resource "kubernetes_ingress" "minio" {
  metadata {
    name      = "minio"
    namespace = var.namespace
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
      //      "traefik.ingress.kubernetes.io/router.tls" : "true"
    }
  }

  spec {
    rule {
      host = "minio.kube.arda"
      http {
        path {
          path = "/"
          backend {
            service_name = "minio"
            service_port = "9000"
          }
        }
      }
    }
  }
}
