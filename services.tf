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

