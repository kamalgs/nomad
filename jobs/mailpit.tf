resource "nomad_job" "mailpit" {
  jobspec = <<-EOT
    job "mailpit" {
      datacenters = ["dc1"]
      type        = "service"

      group "mailpit" {
        count = 1

        network {
          mode = "host"
        }

        task "mailpit" {
          driver = "docker"

          config {
            image        = "axllent/mailpit:latest"
            network_mode = "host"
          }

          env {
            MP_SMTP_AUTH_ACCEPT_ANY    = "true"
            MP_SMTP_AUTH_ALLOW_INSECURE = "true"
            MP_SMTP_BIND_ADDR          = "127.0.0.1:${local.ports.mailpit_smtp}"
            MP_UI_BIND_ADDR            = "127.0.0.1:${local.ports.mailpit_ui}"
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
