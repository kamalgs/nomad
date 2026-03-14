resource "nomad_job" "marimo" {
  jobspec = <<-EOT
    job "marimo" {
      datacenters = ["dc1"]
      type        = "service"

      group "marimo" {
        count = 0

        network {
          mode = "host"
        }

        volume "marimo_data" {
          type      = "host"
          source    = "marimo_data"
          read_only = false
        }

        task "marimo" {
          driver = "docker"

          config {
            image        = "ghcr.io/marimo-team/marimo:latest"
            network_mode = "host"
            args = [
              "marimo", "edit",
              "--host", "127.0.0.1", "--port", "${local.ports.marimo}",
              "--no-token",
            ]
          }

          volume_mount {
            volume      = "marimo_data"
            destination = "/app/notebooks"
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
            http_address = "127.0.0.1:${local.ports.marimo_oauth}"
            upstreams = ["http://127.0.0.1:${local.ports.marimo}"]
            provider = "github"
            client_id = "${var.marimo_oauth_client_id}"
            client_secret = "${var.marimo_oauth_client_secret}"
            cookie_secret = "${var.oauth_cookie_secret}"
            cookie_secure = true
            cookie_name = "_oauth2_proxy_marimo"
            github_users = ["${var.oauth_github_user}"]
            email_domains = ["*"]
            reverse_proxy = true
            set_xauthrequest = true
            proxy_websockets = true
            redirect_url = "https://marimo.${var.domain}/oauth2/callback"
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
