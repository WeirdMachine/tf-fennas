resource "docker_network" "traefik_net" {
  name = "traefik_net"
}

resource "docker_image" "traefik" {
  name = "traefik:v2.2"
}

resource "docker_container" "traefik" {
  name = "traefik"

  image = docker_image.traefik.latest

  # Docker socket
  mounts {
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
    type = "bind"
  }

  # Traefik configuration file
  mounts {
    target = "/etc/traefik/"
    source = "/opt/services/traefik/"
    type = "bind"
    read_only = true
  }

  # HTTP
  ports {
    internal = "80"
    external = "80"
    protocol = "tcp"
  }

  # HTTPS
  ports {
    internal = "443"
    external = "443"
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.traefik_net.name
  }

  restart = "unless-stopped"
  must_run = true

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

  labels = {
    "traefik.http.routers.vault.rule" = "Host(`vault.ando.arda`)"
    "traefik.http.routers.vault.tls" = "true"
    "traefik.enable" = "true"
  }

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

  networks_advanced {
    name = docker_network.traefik_net.name
  }


  restart = "unless-stopped"
  must_run = true

}

####minio
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

  env = [
    "MINIO_ACCESS_KEY=${var.minio_access_key}",
    "MINIO_SECRET_KEY=${var.minio_secret_key}",
  ]

  labels = {
    "traefik.http.routers.minio.rule" = "Host(`minio.ando.arda`)"
    "traefik.http.routers.minio.tls" = "true"
    "traefik.enable" = "true"
  }

  mounts {
    source = "/mnt/p1/minio"
    target = "/data"
    type = "bind"
  }


  mounts {
    source = "/opt/services/minio"
    target = "/root/.minio/"
    type = "bind"
  }

  networks_advanced {
    name = docker_network.traefik_net.name
  }

  restart = "unless-stopped"
  must_run = true

}


