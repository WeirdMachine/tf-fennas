terraform {

  backend "s3" {
    bucket = "hb-wolke-edda"
    key = "terraform/fennas/terraform.tfstate"
    region = "eu-central-1"
  }

}

provider "kubernetes" {}

data "template_file" "flannel" {
  template = file("${path.module}/templates/flannel.yaml")
}

resource "null_resource" "flannel" {
  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${data.template_file.flannel.rendered}\nEOF"
  }
}

resource "kubernetes_service_account" "admin_user" {
  metadata {
    name = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}

resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }

  subject {
    kind = "ServiceAccount"
    name = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}


data "template_file" "fanyaregconf" {
  template = file("${path.module}/templates/fanyaregconf.tpl")
  vars = {
    auth_string = var.docker_registry_fanya_secret
  }
}

resource "kubernetes_secret" "fanyaregcred" {
  metadata {
    name = "fanyaregcred"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" =  data.template_file.fanyaregconf.rendered
  }
}