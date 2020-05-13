resource "docker_network" "monitoring" {
  name = "monitoring_net"
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
    "traefik.http.routers.promtheus.rule" = "Host(`prometheus.ando.arda`)"
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

#### alertmanager ####
resource "docker_image" "alertmanager" {
  name = "quay.io/prometheus/alertmanager"
}

resource "docker_container" "alertmanager" {
  name = "alertmanager"

  image = docker_image.alertmanager.latest

  mounts {
    source = "/opt/services/alertmanager/alertmanager.yml"
    target = "/etc/alertmanager/alertmanager.yml"
    type = "bind"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  restart = "unless-stopped"
  must_run = true

}
#### sachet ####
resource "docker_container" "sachet" {
  name = "sachet"

  image = "sachet-arm"

  mounts {
    source = "/opt/services/sachet/config.yaml"
    target = "/etc/sachet/config.yaml"
    type = "bind"
    read_only = true
  }

  networks_advanced {
    name = docker_network.monitoring.name
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
