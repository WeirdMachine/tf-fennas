resource "kubernetes_service_account" "vault_agent_injector" {
  metadata {
    name      = "vault-agent-injector"
    namespace = var.namespace
    labels = {
      k8s-app = "vault-agent-injector"
    }
  }
}

resource "kubernetes_cluster_role" "vault_agent_injector_clusterrole" {
  metadata {
    name = "vault-agent-injector-clusterrole"
    labels = {
      k8s-app = "vault-agent-injector"
    }
  }
  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations"]
    verbs      = ["get", "list", "watch", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "vault_agent_injector_binding" {
  metadata {
    name = "vault-agent-injector-binding"
    labels = {
      k8s-app = "vault-agent-injector"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "vault-agent-injector-clusterrole"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault-agent-injector"
    namespace = var.namespace
  }
}

resource "kubernetes_service" "vault_agent_injector_service" {
  metadata {
    name      = "vault-agent-injector-svc"
    namespace = var.namespace
    labels = {
      k8s-app = "vault-agent-injector"
    }
  }
  spec {
    port {
      port        = 443
      target_port = 8080
    }
    selector = {
      k8s-app = "vault-agent-injector"
    }
  }
}

// Todo: applied manaully because of problems maybe buggy
//resource "kubernetes_mutating_webhook_configuration" "vault_agent_injector_cfg" {
//  metadata {
//    name = "vault-agent-injector-cfg"
//    labels = {
//      k8s-app = "vault-agent-injector"
//    }
//  }
//  webhook {
//    name = "vault.hashicorp.com"
//    client_config {
//      service {
//        name = "vault-agent-injector-svc"
//        namespace = var.namespace
//        path = "/mutate"
//      }
//      ca_bundle = ""
//    }
//    admission_review_versions = ["v1beta1"]
//    side_effects = "Unknown"
//    rule {
//      api_groups = [""]
//      api_versions = ["v1"]
//      operations = ["CREATE", "UPDATE"]
//      resources = ["pods"]
//    }
//  }
//}

resource "kubernetes_deployment" "vault_agent_injector" {
  metadata {
    name      = "vault-agent-injector"
    namespace = var.namespace
    labels = {
      k8s-app = "vault-agent-injector"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        k8s-app = "vault-agent-injector"
      }
    }
    template {
      metadata {
        name      = "vault-agent-injector"
        namespace = var.namespace
        labels = {
          k8s-app = "vault-agent-injector"
        }
      }
      spec {
        automount_service_account_token = true
        service_account_name            = "vault-agent-injector"

        security_context {
          run_as_non_root = true
          run_as_group    = 1000
          run_as_user     = 100
        }

        node_selector = {
          "kubernetes.io/hostname" = "alda.arda"
        }

        container {
          name  = "sidecar-injector"
          image = "registry.fanya.dev/vault-k8s"
          env {
            name  = "AGENT_INJECT_LISTEN"
            value = ":8080"
          }
          env {
            name  = "AGENT_INJECT_LOG_LEVEL"
            value = "info"
          }
          env {
            name  = "AGENT_INJECT_VAULT_ADDR"
            value = "http://vault.${var.namespace}.svc:8200"
          }
          env {
            name  = "AGENT_INJECT_VAULT_AUTH_PATH"
            value = "auth/kubernetes"
          }
          env {
            name  = "AGENT_INJECT_VAULT_IMAGE"
            value = "vault:1.4.2"
          }
          env {
            name  = "AGENT_INJECT_TLS_AUTO"
            value = "vault-agent-injector-cfg"
          }
          env {
            name  = "AGENT_INJECT_TLS_AUTO_HOSTS"
            value = "vault-agent-injector-svc,vault-agent-injector-svc.${var.namespace},vault-agent-injector-svc.${var.namespace}.svc"
          }
          env {
            name  = "AGENT_INJECT_LOG_FORMAT"
            value = "standard"
          }
          env {
            name  = "AGENT_INJECT_REVOKE_ON_SHUTDOWN"
            value = "false"
          }

          args = ["agent-inject", "2>&1"]

          liveness_probe {
            http_get {
              path   = "/health/ready"
              port   = 8080
              scheme = "HTTPS"
            }
            failure_threshold     = 2
            initial_delay_seconds = 1
            period_seconds        = 2
            success_threshold     = 1
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path   = "/health/ready"
              port   = 8080
              scheme = "HTTPS"
            }
            failure_threshold     = 2
            initial_delay_seconds = 2
            period_seconds        = 2
            success_threshold     = 1
            timeout_seconds       = 5
          }
        }
      }
    }
  }
}
