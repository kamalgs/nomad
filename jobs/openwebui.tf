resource "nomad_job" "openwebui" {
  jobspec = <<-EOT
    job "openwebui" {
      datacenters = ["dc1"]
      type        = "service"

      group "openwebui" {
        count = 0

        network {
          mode = "host"
        }

        volume "openwebui_data" {
          type      = "host"
          source    = "openwebui_data"
          read_only = false
        }

        task "openwebui" {
          driver = "docker"

          config {
            image        = "ghcr.io/open-webui/open-webui:latest"
            network_mode = "host"
          }

          env {
            WEBUI_SECRET_KEY = "${var.openwebui_secret_key}"
            PORT             = "${local.ports.openwebui}"
          }

          volume_mount {
            volume      = "openwebui_data"
            destination = "/app/backend/data"
          }

          resources {
            cpu    = 1000
            memory = 1024
          }
        }

      }
    }
  EOT
}
