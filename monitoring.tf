resource "docker_network" "monitoring" {
  name = "monitoring"
}

#### prometheus ####
resource "docker_image" "prometheus" {
  name = "prom/prometheus"
}

resource "docker_container" "prometheus" {
  name = "prometheus"

  image = docker_image.prometheus.latest

  mounts {
    source = "/opt/services/prometheus"
    target = "/etc/prometheus"
    type = "bind"
  }

  dns = [
    "192.168.2.10"
  ]

  labels = {
    "traefik.http.routers.promtheus.rule" = "Host(`promtheus.ando.arda`)"
    "traefik.http.routers.promtheus.tls" = "true"
    "traefik.enable" = "true"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  networks_advanced {
    name = docker_network.traefik_net.name
  }

  restart = "unless-stopped"
  must_run = true

}

#### grafanna #####
resource "docker_volume" "grafana" {
  name = "grafana"
}

resource "docker_image" "grafana" {
  name = "grafana/grafana"
}

resource "docker_container" "grafana" {
  name = "grafana"

  image = docker_image.grafana.latest

  labels = {
    "traefik.http.routers.grafana.rule" = "Host(`grafana.ando.arda`)"
    "traefik.http.routers.grafana.tls" = "true"
    "traefik.enable" = "true"
  }

  volumes {
    container_path = "/var/lib/grafana"
    volume_name = docker_volume.grafana.name
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  networks_advanced {
    name = docker_network.traefik_net.name
  }

  restart = "unless-stopped"
  must_run = true

}
