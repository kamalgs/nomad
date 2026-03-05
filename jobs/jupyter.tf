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

        volume "jupyter_data" {
          type      = "host"
          source    = "jupyter_data"
          read_only = false
        }

        task "jupyter" {
          driver = "docker"

          config {
            image        = "jupyter/base-notebook:latest"
            network_mode = "host"
            args = [
              "jupyter-lab",
              "--ip=127.0.0.1", "--port=${local.ports.jupyter}", "--no-browser",
              "--ServerApp.token=''", "--ServerApp.password=''",
              "--ServerApp.allow_remote_access=True",
              "--ServerApp.allow_origin='*'",
              "--ServerApp.disable_check_xsrf=True",
              "--ServerApp.websocket_compression_options={}",
              "--notebook-dir=/home/jovyan/notebooks",
            ]
          }

          volume_mount {
            volume      = "jupyter_data"
            destination = "/home/jovyan/notebooks"
          }

          resources {
            cpu    = 500
            memory = 512
          }
        }

        task "oauth2-proxy" {
          driver = "docker"

          config {
            image        = "quay.io/oauth2-proxy/oauth2-proxy:latest"
            network_mode = "host"
            args         = ["--config=/local/oauth2-proxy.cfg"]
          }

          template {
            data        = <<-CFG
            http_address = "127.0.0.1:${local.ports.jupyter_oauth}"
            upstreams = ["http://127.0.0.1:${local.ports.jupyter}"]
            provider = "github"
            client_id = "${var.oauth_client_id}"
            client_secret = "${var.oauth_client_secret}"
            cookie_secret = "${var.oauth_cookie_secret}"
            cookie_secure = true
            cookie_name = "_oauth2_proxy"
            github_users = ["${var.oauth_github_user}"]
            email_domains = ["*"]
            reverse_proxy = true
            set_xauthrequest = true
            proxy_websockets = true
            redirect_url = "https://jupyter.${var.domain}/oauth2/callback"
            CFG
            destination = "local/oauth2-proxy.cfg"
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
