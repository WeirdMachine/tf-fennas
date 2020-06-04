resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = var.namespace
    labels = {
      k8s-app = "vault"
    }
  }
}

resource "kubernetes_config_map" "vault" {
  metadata {
    name      = "vault-config"
    namespace = var.namespace
    labels = {
      k8s-app = "vault"
    }
  }
  data = {
    "vault.hcl" = file("${path.module}/files/vault.hcl")
  }
}

resource "kubernetes_cluster_role_binding" "vault_server_binding" {
  metadata {
    name = "vault-server-binding"
    labels = {
      k8s-app = "vault"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault"
    namespace = var.namespace
  }
}

resource "kubernetes_service" "vault_internal" {
  metadata {
    name      = "vault-internal"
    namespace = var.namespace
    labels = {
      k8s-app = "vault"
    }
    annotations = {
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = true
    }
  }
  spec {
    cluster_ip                  = "None"
    publish_not_ready_addresses = true
    port {
      name        = "http"
      port        = 8200
      target_port = 8200
    }
    port {
      name        = "https-internal"
      port        = 8201
      target_port = 8201
    }
    selector = {
      k8s-app = "vault"
    }
  }
}

resource "kubernetes_service" "vault" {
  metadata {
    name      = "vault"
    namespace = var.namespace
    labels = {
      k8s-app = "vault"
    }
    annotations = {
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = true
    }
  }
  spec {
    publish_not_ready_addresses = true
    port {
      name        = "http"
      port        = 8200
      target_port = 8200
    }
    port {
      name        = "https-internal"
      port        = 8201
      target_port = 8201
    }
    selector = {
      k8s-app = "vault"
    }
  }
}

resource "kubernetes_stateful_set" "vault" {
  metadata {
    name      = "vault"
    namespace = var.namespace
    labels = {
      k8s-app = "vault"
    }
  }

  spec {
    service_name          = "vault-internal"
    pod_management_policy = "Parallel"
    replicas              = 1
    update_strategy {
      type = "OnDelete"
    }

    selector {
      match_labels = {
        k8s-app = "vault"
      }
    }

    template {
      metadata {
        name = "vault"
        labels = {
          k8s-app = "vault"
        }
      }
      spec {

        service_account_name            = "vault"
        automount_service_account_token = true

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_labels = {
                  k8s-app = "vault"
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }

        termination_grace_period_seconds = 10

        security_context {
          run_as_non_root = true
          run_as_group    = 1000
          run_as_user     = 100
        }

        volume {
          name = "config"
          config_map {
            name = "vault-config"
          }
        }

        volume {
          name = "home"
          empty_dir {}
        }

        container {
          name  = "vault"
          image = "vault:1.4.2"

          args = [
            "server"
          ]

          env {
            name = "HOST_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          env {
            name = "VAULT_K8S_POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "VAULT_K8S_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "VAULT_ADDR"
            value = "http://127.0.0.1:8200"
          }
          env {
            name  = "VAULT_API_ADDR"
            value = "https://$(POD_IP):8200"
          }
          env {
            name  = "SKIP_CHOWN"
            value = "true"
          }
          env {
            name  = "SKIP_SETCAP"
            value = "true"
          }
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name  = "VAULT_CLUSTER_ADDR"
            value = "https://$(HOSTNAME).vault-internal:8201"
          }
          env {
            name  = "HOME"
            value = "/home/vault"
          }
          env {
            name  = "AWS_ACCESS_KEY_ID"
            value = var.vault_access_key
          }
          env {
            name  = "AWS_SECRET_ACCESS_KEY"
            value = var.vault_secret_key
          }

          volume_mount {
            name       = "config"
            mount_path = "/vault/config"
          }

          volume_mount {
            name       = "home"
            mount_path = "/home/vault"
          }

          port {
            name           = "http"
            container_port = 8200
          }
          port {
            name           = "https-internal"
            container_port = 8201
          }
          port {
            name           = "http-req"
            container_port = 8202
          }

          readiness_probe {
            exec {
              command = ["/bin/sh", "-ec", "vault status -tls-skip-verify"]
            }
            failure_threshold     = 2
            initial_delay_seconds = 5
            period_seconds        = 3
            success_threshold     = 1
            timeout_seconds       = 5
          }
          lifecycle {
            pre_stop {
              exec {
                command = [
                  "/bin/sh", "-c",
                  # Adding a sleep here to give the pod eviction a
                  # chance to propagate, so requests will not be made
                  # to this pod while it's terminating
                  "sleep 5 && kill -SIGTERM $(pidof vault)",
                ]
              }
            }
          }

        }
      }

    }
  }
}

resource "kubernetes_ingress" "vault" {
  metadata {
    name      = "vault"
    namespace = var.namespace
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
      //      "traefik.ingress.kubernetes.io/router.tls" : "true"
    }
  }

  spec {
    rule {
      host = "vault.kube.arda"
      http {
        path {
          path = "/"
          backend {
            service_name = "vault"
            service_port = "8200"
          }
        }
      }
    }
  }
}
