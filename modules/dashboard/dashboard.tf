resource "null_resource" "dashboard" {
  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${file("${path.module}/files/prometheus.yml")}\nEOF"
  }
}

resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}

resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}