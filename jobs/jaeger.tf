resource "nomad_job" "jaeger" {
  jobspec = <<-EOT
    job "jaeger" {
      datacenters = ["dc1"]
      type        = "service"

      # count=0 — HyperDX owns 4317/4318. Kept as a fallback: bump to 1 and
      # scale hyperdx to 0 to swap back.
      group "jaeger" {
        count = 0

        network {
          mode = "host"
        }

        task "jaeger" {
          driver = "docker"

          config {
            image        = "jaegertracing/all-in-one:1.62"
            network_mode = "host"
          }

          # Ephemeral in-memory storage — fine for a fallback that only
          # runs if HyperDX is down. Binds OTLP receivers on 4317/4318
          # and the UI on 16686 with network_mode=host.
          env {
            COLLECTOR_OTLP_ENABLED = "true"
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
