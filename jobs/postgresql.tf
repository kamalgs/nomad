resource "nomad_job" "postgresql" {
  jobspec = <<-EOT
    job "postgresql" {
      datacenters = ["dc1"]
      type        = "service"

      group "postgresql" {
        count = 1

        network {
          mode = "host"
        }

        volume "postgres_data" {
          type      = "host"
          source    = "postgres_data"
          read_only = false
        }

        task "postgresql" {
          driver = "docker"

          config {
            image        = "postgres:16-alpine"
            force_pull   = false
            network_mode = "host"
          }

          env {
            POSTGRES_DB       = "finadvisor"
            POSTGRES_USER     = "finadvisor"
            POSTGRES_PASSWORD = "${var.postgres_password}"
            PGPORT            = "${local.ports.postgresql}"
          }

          volume_mount {
            volume      = "postgres_data"
            destination = "/var/lib/postgresql/data"
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
