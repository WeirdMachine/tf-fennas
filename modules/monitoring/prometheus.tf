resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"
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
    kind      = "ClusterRole"
    name      = "prometheus"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "prometheus"
    namespace = "monitoring"
  }
}


resource "kubernetes_config_map" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"
  }

  data = {
    "prometheus.yml"   = file("${path.module}/files/prometheus.yml")
    "node.rules"       = file("${path.module}/files/node_rules.yml")
    "blackbox.rules"   = file("${path.module}/files/blackbox_rules.yml")
    "prometheus.rules" = file("${path.module}/files/prometheus_rules.yml")
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"

    labels = {
      k8s-app : "prometheus"
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
        name      = "prometheus"
        namespace = "monitoring"
        labels = {
          k8s-app = "prometheus"
        }
      }
      spec {
        service_account_name            = "prometheus"
        automount_service_account_token = true

        container {
          name  = "prometheus"
          image = "prom/prometheus"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml"
          ]

          port {
            name           = "web"
            container_port = 9090
          }

          volume_mount {
            name       = "prometheus-conf"
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
    name      = "prometheus"
    namespace = "monitoring"
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
      name     = "prometheus"
      protocol = "TCP"
      port     = 9090
    }

  }
}

resource "kubernetes_ingress" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"
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