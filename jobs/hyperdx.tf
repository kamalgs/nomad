resource "nomad_job" "hyperdx" {
  jobspec = <<-EOT
    job "hyperdx" {
      datacenters = ["dc1"]
      type        = "service"

      group "hyperdx" {
        count = 1

        network {
          mode = "host"
        }

        volume "hyperdx_data" {
          type      = "host"
          source    = "hyperdx_data"
          read_only = false
        }

        task "hyperdx" {
          driver = "docker"

          config {
            image        = "docker.hyperdx.io/hyperdx/hyperdx-all-in-one"
            network_mode = "host"
          }

          env {
            # External URL Caddy reverse-proxies to — HyperDX uses this for
            # post-login redirects and absolute URLs in emails / API refs.
            # Without this it emits http://localhost:8080 and breaks login.
            FRONTEND_URL = "https://hyperdx.gkamal.online"
          }

          volume_mount {
            volume      = "hyperdx_data"
            destination = "/var/lib/clickhouse"
          }

          resources {
            cpu    = 2000
            memory = 2048
          }
        }
      }
    }
  EOT
}
