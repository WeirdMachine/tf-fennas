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

resource "null_resource" "flannel" {
  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${file("${path.module}/files/flannel.yaml")}\nEOF"
  }
}