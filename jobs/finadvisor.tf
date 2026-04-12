resource "nomad_job" "finadvisor" {
  jobspec = <<-EOT
    job "finadvisor" {
      datacenters = ["dc1"]
      type        = "service"

      group "finadvisor" {
        count = 0

        network {
          mode = "host"
        }

        volume "finadvisor_data" {
          type      = "host"
          source    = "finadvisor_data"
          read_only = false
        }

        task "finadvisor" {
          driver = "docker"

          config {
            image        = "finadvisor:local"
            force_pull   = false
            network_mode = "host"
          }

          env {
            ANTHROPIC_API_KEY          = "${var.finadvisor_anthropic_api_key}"
            GRADIO_SERVER_NAME         = "127.0.0.1"
            GRADIO_SERVER_PORT         = "${local.ports.finadvisor}"
            SUBPRIME_DATA_DIR          = "/app/state/data"
            SUBPRIME_CONVERSATIONS_DIR = "/app/state/conversations"
          }

          volume_mount {
            volume      = "finadvisor_data"
            destination = "/app/state"
          }

          resources {
            cpu    = 500
            memory = 768
          }
        }
      }
    }
  EOT
}
