resource "nomad_job" "hyperdx" {
  jobspec = <<-EOT
    job "hyperdx" {
      datacenters = ["dc1"]
      type        = "service"

      group "hyperdx" {
        count = 0

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
