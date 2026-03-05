resource "nomad_job" "nats_chat" {
  jobspec = <<-EOT
    job "nats-chat" {
      datacenters = ["dc1"]
      type        = "service"

      # ── upstream nats-server ──────────────────────────────────────────
      group "nats" {
        count = 1

        network {
          mode = "host"
        }

        task "nats" {
          driver = "docker"

          config {
            image        = "nats:latest"
            network_mode = "host"
            args         = [
              "--port", "${local.ports.nats}",
              "--jetstream",
            ]
          }

          resources {
            cpu    = 200
            memory = 256
          }
        }
      }

      # ── leaf node gateway ─────────────────────────────────────────────
      group "leaf-gateway" {
        count = 1

        network {
          mode = "host"
        }

        task "leaf-gateway" {
          driver = "docker"

          config {
            image        = "nats-leaf-gateway:local"
            network_mode = "host"
            args         = [
              "--port", "${local.ports.nats_leaf}",
              "--ws-port", "${local.ports.nats_leaf_ws}",
              "--hub", "nats://127.0.0.1:${local.ports.nats}",
            ]
          }

          resources {
            cpu    = 200
            memory = 256
          }
        }
      }

      # ── chat web app ──────────────────────────────────────────────────
      group "chat-app" {
        count = 1

        network {
          mode = "host"
        }

        task "chat-app" {
          driver = "docker"

          config {
            image        = "caddy:2-alpine"
            network_mode = "host"
            entrypoint   = ["/bin/sh", "-c"]
            args         = [
              "caddy file-server --listen :${local.ports.nats_chat} --root /srv",
            ]
            volumes = [
              "/home/agent/projects/nats_rust/sample-app:/srv:ro",
            ]
          }

          resources {
            cpu    = 100
            memory = 64
          }
        }
      }
    }
  EOT
}
