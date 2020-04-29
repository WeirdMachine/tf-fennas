terraform {

  backend "s3" {
    bucket = "hb-wolke-edda"
    key = "terraform/fennas/terraform.tfstate"
    region = "eu-central-1"
  }



  required_providers {
    docker = "< 2.7.0"
  }

}

provider "docker" {
  host = "ssh://ando"

  registry_auth {
    address = "registry.fanya.dev"
    username = "ando"
    password = var.docker_registry_pw
  }
}


####vault
resource "docker_image" "vault" {
  name = "vault"
}

resource "docker_container" "vault" {
  name = "vault"

  image = docker_image.vault.latest

  command = [
    "server"
  ]

  capabilities {
    add = [
      "IPC_LOCK"
    ]
  }

  mounts {
    source = "/opt/services/vault/config"
    target = "/vault/config"
    type = "bind"
  }

  mounts {
    source = "/opt/services/vault/file"
    target = "/vault/file"
    type = "bind"
  }

  ports {
    internal = "8200"
    external = "8200"
    protocol = "tcp"
  }

  restart = "unless-stopped"
  must_run = true

}

resource "docker_image" "minio" {
  name = "registry.fanya.dev/minio-arm"
}

resource "docker_container" "minio" {
  name = "minio"

  image = docker_image.minio.latest

  command = [
    "server",
    "/data"
  ]

  mounts {
    target = "/data"
    source = "/mnt/p1/minio"
    type = "bind"
  }

  mounts {
    source = "/opt/services/minio/"
    target = "/root/.minio/"
    type = "bind"
  }

  ports {
    internal = "9000"
    external = "9000"
    protocol = "tcp"
  }

  restart = "unless-stopped"
  must_run = true

}
