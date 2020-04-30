####prometheus
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

  ports {
    internal = "9090"
    external = "9090"
    protocol = "tcp"
  }

  dns = [
    "192.168.2.10"
  ]

  restart = "unless-stopped"
  must_run = true

}
