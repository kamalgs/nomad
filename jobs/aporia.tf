resource "nomad_job" "aporia" {
  jobspec = <<-EOT
    job "aporia" {
      datacenters = ["dc1"]
      type        = "service"

      group "aporia" {
        count = 1

        network {
          mode = "host"
        }

        task "aporia" {
          driver = "docker"

          config {
            image        = "aporia:local"
            force_pull   = false
            network_mode = "host"
          }

          env {
            ENV                   = "production"
            FRONTEND_STATIC_DIR   = "/app/static"
            PORT                  = "${local.ports.aporia}"
            # Fireworks AI — frontier-class LLM via OpenAI-compatible API
            FIREWORKS_API_KEY     = "${var.fireworks_api_key}"
            FIREWORKS_MODEL       = "${var.aporia_model}"
            # Disable CORS in prod (Caddy terminates TLS + adds headers)
          }

          resources {
            cpu    = 500
            memory = 512
          }
        }
      }
    }
  EOT
}
