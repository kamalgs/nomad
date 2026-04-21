# Blue-green finadvisor deployment.
#
#   finadvisor-blue  — port 8091, OTEL service name 'finadvisor-web-blue'
#   finadvisor-green — port 8093, OTEL service name 'finadvisor-web-green'
#
# Both always run count=1. Caddy's `/etc/caddy/active-finadvisor.caddy`
# include decides which one public traffic hits. Smoke tests address the
# inactive colour via the `X-Benji-Color: blue|green` header (Caddy
# matcher).
#
# Deploy flow: scripts/blue-green-deploy.sh in the subprime repo.

locals {
  # Shared job template. `$${color}`, `$${port}`, `$${image}` are kept as
  # literal `${...}` in the string (HCL `$${…}` → literal `${…}`); the two
  # resources below swap them per colour with replace().
  #
  # The `${var.…}` references ARE interpolated at template-build time, so
  # they end up with their resolved values in both copies.
  finadvisor_jobspec = <<-TEMPLATE
    job "finadvisor-$${color}" {
      datacenters = ["dc1"]
      type        = "service"

      group "finadvisor" {
        count = 1

        network {
          mode = "host"
        }

        volume "finadvisor_data" {
          type      = "host"
          source    = "finadvisor_data"
          read_only = false
        }

        task "migrate" {
          driver = "docker"
          # Prestart needs write access to the host-mounted volume
          # (owned by host uid). Run as root, then chown the state dir
          # to uid 1001 so the runtime task (USER benji = 1001) can
          # use it. The runtime task keeps the image's non-root USER.
          user = "root"
          lifecycle {
            hook    = "prestart"
            sidecar = false
          }
          config {
            image        = "$${image}"
            force_pull   = false
            network_mode = "host"
            command      = "sh"
            args = [
              "-c",
              "subprime data migrate && chown -R 1001:1001 /app/state",
            ]
          }
          env {
            SUBPRIME_DATA_DIR = "/app/state/data"
          }
          volume_mount {
            volume      = "finadvisor_data"
            destination = "/app/state"
          }
          resources {
            cpu    = 200
            memory = 256
          }
        }

        task "finadvisor" {
          driver = "docker"

          config {
            image        = "$${image}"
            force_pull   = false
            network_mode = "host"
            command      = "uvicorn"
            args = [
              "apps.web.main:create_app",
              "--factory",
              "--host", "0.0.0.0",
              "--port", "$${port}",
              "--timeout-keep-alive", "5",
            ]
          }

          env {
            ANTHROPIC_API_KEY          = "${var.finadvisor_anthropic_api_key}"
            TOGETHER_API_KEY           = "${var.together_api_key}"
            ADVISOR_MODEL              = "together:Qwen/Qwen3-235B-A22B-Instruct-2507-tput"
            REFINE_MODEL               = "together:Qwen/Qwen3-235B-A22B-Instruct-2507-tput"
            SUBPRIME_DATA_DIR          = "/app/state/data"
            SUBPRIME_CONVERSATIONS_DIR = "/app/state/conversations"
            DATABASE_URL               = "postgresql://finadvisor:${var.postgres_password}@localhost:${local.ports.postgresql}/finadvisor"
            SMTP_HOST                  = "${var.smtp_host}"
            SMTP_PORT                  = "${var.smtp_port}"
            SMTP_USER                  = "${var.smtp_user}"
            SMTP_PASSWORD              = "${var.smtp_password}"
            SMTP_FROM                  = "${var.smtp_from}"
            SUBPRIME_OTP_CHEAT         = "${var.subprime_otp_cheat}"
            SUBPRIME_COLOR             = "$${color}"
            OTEL_SERVICE_NAME           = "finadvisor-web-$${color}"
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:${local.ports.otel_http}"
            OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
            OTEL_EXPORTER_OTLP_HEADERS  = "authorization=${var.hyperdx_ingest_token}"
            OTEL_METRIC_EXPORT_INTERVAL = "30000"
            OTEL_RESOURCE_ATTRIBUTES    = "subprime.color=$${color}"
            SUBPRIME_EXPERIMENT         = "${var.subprime_experiment}"
            SUBPRIME_PROMPT_VERSION     = "${var.subprime_prompt_version}"
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
  TEMPLATE
}

resource "nomad_job" "finadvisor_blue" {
  jobspec = replace(replace(replace(local.finadvisor_jobspec,
    "$${color}", "blue"),
    "$${port}", tostring(local.ports.finadvisor_blue)),
    "$${image}", var.finadvisor_blue_image)
}

resource "nomad_job" "finadvisor_green" {
  jobspec = replace(replace(replace(local.finadvisor_jobspec,
    "$${color}", "green"),
    "$${port}", tostring(local.ports.finadvisor_green)),
    "$${image}", var.finadvisor_green_image)
}
