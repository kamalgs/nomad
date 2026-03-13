variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "gateway_api_key" {
  type      = string
  sensitive = true
}

resource "nomad_job" "llm_gateway" {
  jobspec = <<-EOT
    job "llm-gateway" {
      datacenters = ["dc1"]
      type        = "service"

      group "llm-gateway" {
        count = 0

        network {
          mode = "host"
        }

        task "krakend" {
          driver = "docker"

          config {
            image        = "krakend-llm-gateway:local"
            network_mode = "host"
          }

          env {
            KRAKEND_PORT    = "${local.ports.llm_gateway}"
            OPENAI_API_KEY  = "${var.openai_api_key}"
            GATEWAY_API_KEY = "${var.gateway_api_key}"
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
