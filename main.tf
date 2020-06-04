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

module "network" {
  source = "./modules/networking"
}

module "dashboard" {
  source = "./modules/dashboard"
}

resource "kubernetes_namespace" "infrastructure" {
  metadata {
    name = "infra"
  }
}

module "gluster-default" {
  source    = "./modules/gluster"
  namespace = "default"
}

module "gluster-infra" {
  source    = "./modules/gluster"
  namespace = "infra"
}

module "minio" {
  source           = "./modules/minio"
  minio_access_key = var.minio_access_key
  minio_secret_key = var.minio_secret_key
  namespace = "infra"
}

module "monitoring" {
  source         = "./modules/monitoring"
  telegram_token = var.telegram_token
}
