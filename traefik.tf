resource "kubernetes_service_account" "traefik_ingress_controller" {
  metadata {
    name = "traefik-ingress-controller"
  }
}

resource "kubernetes_cluster_role" "traefik_ingress_controller" {
  metadata {
    name = "traefik-ingress-controller"
  }

  rule {
    api_groups = [""]
    resources = [
      "services",
      "endpoints",
      "secrets"]
    verbs = [
      "get",
      "list",
      "watch"]
  }

  rule {
    api_groups = [
      "extensions"]
    resources = [
      "ingresses"]
    verbs = [
      "get",
      "list",
      "watch"]
  }

  rule {
    api_groups = [
      "extensions"]
    resources = [
      "ingresses/status"]
    verbs = [
      "update"]
  }
}

resource "kubernetes_cluster_role_binding" "traefik_ingress_controller" {
  metadata {
    name = "traefik-ingress-controller"
  }

  role_ref {
    kind = "ClusterRole"
    name = "traefik-ingress-controller"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind = "ServiceAccount"
    name = "traefik-ingress-controller"
    namespace = "default"
  }
}


resource "kubernetes_daemonset" "traefik_ingress_controller" {
  metadata {
    name = "traefik"
    labels = {
      app= "traefik"
    }
  }

  spec {
    selector {
      match_labels = {
        app= "traefik"
      }
    }

    template {
      metadata {
        labels = {
          app= "traefik"
        }
      }

      spec {
        service_account_name = "traefik-ingress-controller"
        termination_grace_period_seconds = 60
        automount_service_account_token = true

        toleration {
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }

        container {
          image = "traefik:v2.2"
          name = "traefik"

          args = [
            "--api",
            "--api.insecure",
            "--log.level=DEBUG",
            "--entrypoints.web.address=:80",
            "--entrypoints.websecure.address=:443",
            "--providers.kubernetesingress"
          ]

          port {
            name = "web"
            container_port = 80
          }

          port {
            name = "websecure"
            container_port = 443
          }

          port {
            name = "admin"
            container_port = 8080
          }

        }
      }
    }
  }
}

resource "kubernetes_service" "traefik_ingress_service" {
  metadata {
    name = "traefik"
  }

  spec {
    selector = {
      app = "traefik"
    }

    type = "NodePort"

    port {
      protocol = "TCP"
      port = 80
      target_port = 80
      name = "web"
      node_port = 32080
    }

    port {
      protocol = "TCP"
      port = 443
      target_port = 443
      name = "websecure"
      node_port = 32443
    }

    port {
      protocol = "TCP"
      port = 8080
      target_port = 8080
      name = "admin"
      node_port = 32277
    }

  }
}


resource "kubernetes_ingress" "whoami_http" {
  metadata {
    name = "whoami-http"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    }
  }

  spec {
    rule {
      host = "kube.arda"
      http {
        path {
          path = "/whoami"
          backend {
            service_name = "whoami"
            service_port = "80"
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "whoami_https" {
  metadata {
    name = "whoami-https"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls": "true"
    }
  }

  spec {
    rule {
      host = "kube.arda"
      http {
        path {
          path = "/whoami"
          backend {
            service_name = "whoami"
            service_port = "80"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "whoami" {
  metadata {
    name = "whoami"
    labels = {
      k8s-app = "whoami"
      name = "whoami"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
          k8s-app= "whoami"
          name= "whoami"
      }
    }
    template {
      metadata {
        labels = {
          k8s-app = "whoami"
          name = "whoami"
        }
      }
      spec {
        toleration {
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
        container {
          name = "whoami"
          image = "containous/whoami"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami" {
  metadata {
    name = "whoami"
  }

  spec {

    port {
      name = "http"
      port = 80
    }

    selector = {
      k8s-app= "whoami"
      name= "whoami"
    }
  }
}


