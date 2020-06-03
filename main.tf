terraform {

  backend "s3" {
    bucket = "hb-wolke-edda"
    key    = "terraform/fennas/terraform.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    docker = "< 2.7.0"
  }

}

provider "docker" {
  host = "ssh://192.168.2.10"
}

provider "kubernetes" {}

resource "docker_container" "haproxy" {
  image = "haproxy"
  name  = "haproxy"


  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  mounts {
    source    = "/opt/services/haproxy/"
    target    = "/usr/local/etc/haproxy"
    type      = "bind"
    read_only = true
  }

  restart  = "unless-stopped"
  must_run = true
}


data "template_file" "flannel" {
  template = file("${path.module}/templates/flannel.yaml")
}

resource "null_resource" "flannel" {
  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${data.template_file.flannel.rendered}\nEOF"
  }
}

module "dashboard" {
  source = "./modules/dashboard"
}

module "minio" {
  source           = "./modules/minio"
  minio_access_key = var.minio_access_key
  minio_secret_key = var.minio_secret_key
}

module "monitoring" {
  source         = "./modules/monitoring"
  telegram_token = var.telegram_token
}