resource "nomad_job" "jupyter" {
  jobspec = <<-EOT
    job "jupyter" {
      datacenters = ["dc1"]
      type        = "service"

      group "jupyter" {
        count = 0

        network {
          mode = "host"
        }

        task "jupyter" {
          driver = "raw_exec"
          user   = "agent"

          config {
            command = "/home/agent/.local/share/mise/installs/python/3.12.12/bin/jupyter-lab"
            args    = ["--config=/home/agent/.jupyter/jupyter_lab_config.py"]
          }

          env {
            PATH = "/home/agent/.local/share/mise/installs/python/3.12.12/bin:/usr/local/bin:/usr/bin:/bin"
          }

          resources {
            cpu    = 500
            memory = 512
          }
        }

        task "oauth2-proxy" {
          driver = "raw_exec"

          config {
            command = "/usr/local/bin/oauth2-proxy"
            args    = ["--config=/etc/oauth2-proxy/oauth2-proxy.cfg"]
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
