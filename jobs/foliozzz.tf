resource "nomad_job" "foliozzz" {
  jobspec = <<EOT
    job "foliozzz" {
      datacenters = ["dc1"]
      type        = "service"

      group "foliozzz" {
        count = 1

        network {
          mode = "host"
        }

        volume "data" {
          type      = "host"
          source    = "foliozzz_data"
          read_only = true
        }

        task "foliozzz" {
          driver = "docker"

          config {
            image = "caddy:2-alpine"
            network_mode = "host"
            entrypoint = ["/bin/sh", "-c"]
            args = ["caddy run --config /usr/share/caddy/Caddyfile"]
          }

          volume_mount {
            volume      = "data"
            destination = "/usr/share/caddy"
            read_only = true
          }

          resources {
            cpu    = 256
            memory = 256
          }
        }
      }
    }
EOT
}
