resource "docker_image" "pyload" {
  name = "linuxserver/pyload"
}

resource "docker_container" "pyload" {
  name = "pyload"

  image = docker_image.pyload.latest

  env = [
    "PUID=0",
    "PGID=0",
    "TZ=Europe/Berlin"
  ]

  labels = {
    "traefik.http.routers.pyload.rule" = "Host(`pyload.ando.arda`)"
    "traefik.http.routers.pyload.tls" = "true"
    "traefik.http.services.pyload.loadbalancer.server.port" = "8000"
    "traefik.enable" = "true"
  }

  mounts {
    source = "/mnt/p1/pyload"
    target = "/downloads"
    type = "bind"
  }

  mounts {
    source = "/opt/services/pyload"
    target = "/config"
    type = "bind"
  }

  networks_advanced {
    name = docker_network.traefik_net.name
  }

  cpu_shares = "512"
  cpu_set = "2-3"

  restart = "unless-stopped"
  must_run = true

}

resource "docker_container" "plex" {
  name = "plex"

  image = "plex-pms-arm"

  env = [
    "TZ=Europe/Berlin"
  ]

  labels = {
    "traefik.http.routers.plex.rule" = "Host(`plex.ando.arda`)"
    "traefik.http.routers.plex.tls" = "true"
    "traefik.http.services.plex.loadbalancer.server.port" = "32400"
    "traefik.enable" = "true"
  }

  mounts {
    source = "/mnt/p1/plex"
    target = "/data "
    type = "bind"
  }

  mounts {
    source = "/opt/services/plex"
    target = "/config"
    type = "bind"
  }

  mounts {
    source = "/tmp"
    target = "/transcode"
    type = "bind"
  }

  cpu_shares = "512"

  ports {
    internal = 1900
    external = 1900
    protocol = "udp"
  }

  ports {
    internal = 32469
    external = 32469
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.traefik_net.name
  }

  restart = "unless-stopped"
  must_run = true

}

