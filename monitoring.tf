resource "kubernetes_service_account" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }

  rule {
    api_groups = [
      ""]
    resources = [
      "nodes",
      "nodes/proxy",
      "services",
      "endpoints",
      "pods"]
    verbs = [
      "get",
      "list",
      "watch"]
  }

  rule {
    api_groups = [
      "extensions"
    ]
    resources = [
      "ingresses"
    ]
    verbs = [
      "get",
      "list",
      "watch"]
  }

  rule {
    non_resource_urls = [
      "/metrics"]
    verbs = [
      "get"]
  }

}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "prometheus"
  }
  subject {
    kind = "ServiceAccount"
    name = "prometheus"
  }
}


resource "kubernetes_config_map" "prometheus" {
  metadata {
    name = "prometheus"
  }

  data = {
    "prometheus.yml" = file("${path.module}/templates/prometheus.yml")
  }
}


resource "kubernetes_deployment" "prometheus" {
  metadata {
    name = "prometheus"

    labels = {
      k8s-app: "prometheus"
    }
  }


  spec {
    replicas = 1
    selector {
      match_labels = {
        k8s-app = "prometheus"
      }
    }
    template {

      metadata {
        name = "prometheus"
        labels = {
          k8s-app = "prometheus"
        }
      }
      spec {
        service_account_name = "prometheus"
        automount_service_account_token = true

        container {
          name = "prometheus"
          image = "prom/prometheus"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml"
          ]

          port {
            name = "web"
            container_port = 9090
          }

          volume_mount {
            name = "prometheus-conf"
            mount_path = "/etc/prometheus"
          }
        }

        volume {
          name = "prometheus-conf"
          config_map {
            name = "prometheus"
          }
        }

      }
    }
  }
}


resource "kubernetes_service" "prometheus" {
  metadata {
    name = "prometheus"
    annotations = {
      "prometheus.io/scrape" = true
    }
    labels = {
      name = "prometheus"
    }
  }
  spec {
    selector = {
      k8s-app = "prometheus"
    }

    port {
      name = "prometheus"
      protocol = "TCP"
      port = 9090
    }

  }
}

resource "kubernetes_ingress" "prometheus" {
  metadata {
    name = "prometheus"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
      //      "traefik.ingress.kubernetes.io/router.tls": "true"
    }
  }

  spec {
    rule {
      host = "prometheus.kube.arda"
      http {
        path {
          path = "/"
          backend {
            service_name = "prometheus"
            service_port = "9090"
          }
        }
      }
    }
  }
}

resource "kubernetes_daemonset" "node_exporter" {
  metadata {
    name = "node-exporter"
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
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }

        container {
          name = "node-exporter"
          image = "prom/node-exporter"

          port {
            container_port = 9100
            host_port = 9100
            name = "scrape"
          }
        }

        host_pid = true
        host_network = true
      }
    }
  }
}

resource "kubernetes_service" "node_exporter" {
  metadata {
    name = "node-exporter"
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
      name = "scrape"
      port = 9100
      protocol = "TCP"
    }

    selector = {
      k8s-app = "node-exporter"
    }
  }
}

resource "kubernetes_service_account" "alertmanager" {
  metadata {
    name = "alertmanager"
  }
}

resource "kubernetes_config_map" "alertmanager" {
  metadata {
    name = "alertmanager"
    labels = {
      k8s-app = "alertmanager"
    }
  }

  data = {
    "alertmanager.yml" = file("${path.module}/templates/alertmanager.yml")
  }
}

resource "kubernetes_service" "alertmanager" {
  metadata {
    name = "alertmanager"
    labels = {
      k8s-app = "alertmanager"
    }
  }

  spec {
    port {
      name = "http"
      port = 9093
      protocol = "TCP"
    }
    selector = {
      k8s-app = "alertmanager"
    }
  }
}

resource "kubernetes_stateful_set" "alertmanager" {
  metadata {
    name = "alertmanager"
    labels = {
      k8s-app = "alertmanager"
    }
  }
  spec {
    service_name = "alertmanager"
    selector {
      match_labels = {
        k8s-app = "alertmanager"
      }
    }
    template {
      metadata {}
    }
  }
}


resource "kubernetes_deployment" "grafana" {
  metadata {
    name = "grafana"
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "grafana"
      }
    }
    template {
      metadata {
        name = "grafana"
        labels = {
          k8s-app = "grafana"
        }
      }
      spec {
        container {
          name = "grafana"
          image = "grafana/grafana:latest"

          env {
            name = "GF_INSTALL_PLUGINS"
            value = "grafana-piechart-panel,devopsprodigy-kubegraf-app"
          }

          port {
            name = "grafana"
            container_port = 3000
          }

          volume_mount {
            mount_path = "/var/lib/grafana"
            name = "grafana-storage"
          }
        }

        //Todo: use persistent volume
        volume {
          name = "grafana-storage"
          empty_dir {}
        }
      }
    }
  }
}


resource "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port" = "3000"
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
    name = "grafana"
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