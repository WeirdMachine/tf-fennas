disable_mlock = true
ui = true
default_lease_ttl = "168h"
max_lease_ttl = "8760h"

listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}

storage "s3" {
  bucket      = "vault"
  endpoint    = "minio.infra.svc:9000"
  region     = "us-east-1"
  s3_force_path_style = "true"
  disable_ssl = "true"
}

telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

