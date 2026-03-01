resource "nomad_job" "gateway" {
  jobspec = <<-EOT
    job "gateway" {
      datacenters = ["dc1"]
      type        = "service"

      group "caddy" {
        count = 1

        network {
          mode = "host"
        }

        volume "caddy_data" {
          type      = "host"
          source    = "caddy_data"
          read_only = false
        }

        volume "caddy_apps" {
          type      = "host"
          source    = "caddy_apps"
          read_only = true
        }

        task "caddy" {
          driver = "docker"

          config {
            image        = "caddy:alpine"
            network_mode = "host"

            volumes = [
              "local/Caddyfile:/etc/caddy/Caddyfile:ro",
            ]
          }

          volume_mount {
            volume      = "caddy_data"
            destination = "/data"
            read_only   = false
          }

          volume_mount {
            volume      = "caddy_apps"
            destination = "/apps"
            read_only   = true
          }

          template {
            data        = "import /apps/*.caddy"
            destination = "local/Caddyfile"
            change_mode = "restart"
          }

          resources {
            cpu    = 200
            memory = 256
          }
        }
      }
    }
  EOT
}
