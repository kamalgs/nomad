resource "nomad_job" "finadvisor" {
  jobspec = <<-EOT
    job "finadvisor" {
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

        # Pre-start: apply DuckDB schema migrations while no one else has
        # the DB open. The service task below uses read-only connections
        # exclusively, so this is the one chance to write DDL.
        task "migrate" {
          driver = "docker"
          lifecycle {
            hook    = "prestart"
            sidecar = false
          }
          config {
            image        = "finadvisor:local"
            force_pull   = false
            network_mode = "host"
            command      = "subprime"
            args         = ["data", "migrate"]
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
            image        = "finadvisor:local"
            force_pull   = false
            network_mode = "host"
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
            # OpenTelemetry → HyperDX all-in-one (jobs/hyperdx.tf).
            # Listens on localhost:4318 (OTLP HTTP) via host networking.
            # Jaeger (jobs/jaeger.tf) is kept as a count=0 fallback.
            OTEL_SERVICE_NAME               = "finadvisor-web"
            OTEL_EXPORTER_OTLP_ENDPOINT     = "http://localhost:${local.ports.otel_http}"
            OTEL_EXPORTER_OTLP_PROTOCOL     = "http/protobuf"
            OTEL_METRIC_EXPORT_INTERVAL     = "30000"
            # Slicing label for Jaeger / Prometheus. Set via terraform.tfvars
            # to separate prod traffic from experiment runs sharing this app.
            SUBPRIME_EXPERIMENT             = "${var.subprime_experiment}"
            SUBPRIME_PROMPT_VERSION         = "${var.subprime_prompt_version}"
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
