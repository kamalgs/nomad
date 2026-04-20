resource "nomad_job" "jaeger" {
  jobspec = <<-EOT
    job "jaeger" {
      datacenters = ["dc1"]
      type        = "service"

      group "jaeger" {
        count = 1

        network {
          mode = "host"
        }

        # Persist spans to disk so restarts don't wipe the last few hours of
        # traces. jaegertracing/all-in-one stores badger data under /badger.
        volume "jaeger_data" {
          type      = "host"
          source    = "jaeger_data"
          read_only = false
        }

        task "jaeger" {
          driver = "docker"

          config {
            image        = "jaegertracing/all-in-one:1.62"
            network_mode = "host"
          }

          # Enable Badger storage (on-disk) and the OTLP receivers.
          env {
            SPAN_STORAGE_TYPE            = "badger"
            BADGER_EPHEMERAL             = "false"
            BADGER_DIRECTORY_VALUE       = "/badger/data"
            BADGER_DIRECTORY_KEY         = "/badger/key"
            COLLECTOR_OTLP_ENABLED       = "true"
            # Defaults bind to 0.0.0.0 on ${local.ports.otel_grpc} (4317)
            # and ${local.ports.otel_http} (4318). The UI serves on
            # ${local.ports.jaeger_ui} (16686). With network_mode=host
            # these are reachable at http://localhost:4318 from finadvisor.
          }

          volume_mount {
            volume      = "jaeger_data"
            destination = "/badger"
          }

          resources {
            cpu    = 500
            memory = 1024
          }
        }
      }
    }
  EOT
}
