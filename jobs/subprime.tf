resource "nomad_job" "subprime" {
  jobspec = <<-EOT
    job "subprime" {
      datacenters = ["dc1"]
      type        = "service"

      group "subprime" {
        count = 0

        network {
          mode = "host"
        }

        volume "subprime_data" {
          type      = "host"
          source    = "subprime_data"
          read_only = false
        }

        task "subprime" {
          driver = "docker"

          config {
            image        = "subprime:local"
            network_mode = "host"
          }

          env {
            ANTHROPIC_API_KEY           = "${var.subprime_anthropic_api_key}"
            GRADIO_SERVER_NAME          = "127.0.0.1"
            GRADIO_SERVER_PORT          = "${local.ports.subprime}"
            SUBPRIME_DATA_DIR           = "/app/state/data"
            SUBPRIME_CONVERSATIONS_DIR  = "/app/state/conversations"
          }

          volume_mount {
            volume      = "subprime_data"
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
