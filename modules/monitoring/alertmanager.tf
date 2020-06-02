resource "kubernetes_service_account" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = "monitoring"
  }
}

resource "kubernetes_config_map" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = "monitoring"
    labels = {
      k8s-app = "alertmanager"
    }
  }

  data = {
    "alertmanager.yml" = file("${path.module}/files/alertmanager.yml")
  }
}

data "template_file" "sachet" {
  template = file("${path.module}/templates/sachet.tpl")
  vars = {
    telegram_token = var.telegram_token
  }
}

resource "kubernetes_config_map" "sachet" {
  metadata {
    name      = "sachet"
    namespace = "monitoring"
    labels = {
      k8s-app = "sachet"
    }
  }

  data = {
    "config.yaml" = data.template_file.sachet.rendered
  }
}

resource "kubernetes_service" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = "monitoring"
    labels = {
      k8s-app = "alertmanager"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "9093"
    }
  }

  spec {
    port {
      name     = "http"
      port     = 9093
      protocol = "TCP"
    }
    selector = {
      k8s-app = "alertmanager"
    }
  }
}

resource "kubernetes_deployment" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = "monitoring"
    labels = {
      k8s-app = "alertmanager"
    }
  }
  spec {
    selector {
      match_labels = {
        k8s-app = "alertmanager"
      }
    }
    template {
      metadata {
        name      = "alertmanager"
        namespace = "monitoring"
        labels = {
          k8s-app = "alertmanager"
        }
      }
      spec {
        container {
          name  = "alertmanager"
          image = "quay.io/prometheus/alertmanager"

          port {
            container_port = 9093
            name           = "http"
          }

          readiness_probe {
            http_get {
              path = "/#/status"
              port = "9093"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          volume_mount {
            mount_path = "/etc/alertmanager"
            name       = "alertmanager"
          }
        }

        container {
          name  = "sachet"
          image = "registry.fanya.dev/sachet-arm"

          port {
            container_port = 9876
          }

          volume_mount {
            mount_path = "/etc/sachet/"
            name       = "sachet"
          }
        }

        volume {
          name = "alertmanager"
          config_map {
            name = "alertmanager"
          }
        }

        volume {
          name = "sachet"
          config_map {
            name = "sachet"
          }
        }
      }
    }
  }
}