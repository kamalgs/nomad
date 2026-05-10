resource "nomad_job" "pi_dashboard" {
  jobspec = <<-EOT
    job "pi-dashboard" {
      datacenters = ["dc1"]
      type        = "service"

      group "pi-dashboard" {
        count = 1

        network {
          mode = "host"
        }

        # ── pi-agent-dashboard server (raw_exec) ───────────────────────────
        task "dashboard" {
          driver = "raw_exec"

          config {
            command = "/home/agent/.local/share/mise/installs/node/22.22.0/bin/node"
            args = [
              "--import",
              "file:///home/agent/.local/share/mise/installs/node/22.22.0/lib/node_modules/@mariozechner/pi-coding-agent/node_modules/@mariozechner/jiti/lib/jiti-register.mjs",
              "${var.pi_dashboard_repo}/packages/server/src/cli.ts",
              "--port", "${local.ports.pi_dashboard}",
            ]
          }

          env {
            HOME             = "/home/agent"
            PATH             = "/home/agent/.local/bin:/home/agent/.local/share/mise/installs/node/22.22.0/bin:/usr/local/bin:/usr/bin:/bin"
            NODE_ENV         = "production"
            PI_DASHBOARD_PORT = "${local.ports.pi_dashboard}"
          }

          resources {
            cpu    = 800
            memory = 768
          }
        }

        # ── oauth2-proxy (GitHub) ──────────────────────────────────────────
        task "oauth2-proxy" {
          driver = "docker"

          config {
            image        = "quay.io/oauth2-proxy/oauth2-proxy:latest"
            network_mode = "host"
            args         = ["--config=/local/oauth2-proxy.cfg"]
          }

          template {
            data        = <<-CFG
            http_address = "127.0.0.1:${local.ports.pi_dashboard_oauth}"
            upstreams = ["http://127.0.0.1:${local.ports.pi_dashboard}"]
            provider = "github"
            client_id = "${var.pi_oauth_client_id}"
            client_secret = "${var.pi_oauth_client_secret}"
            cookie_secret = "${var.pi_oauth_cookie_secret}"
            cookie_secure = true
            cookie_name = "_oauth2_proxy_pi"
            github_users = ["${var.oauth_github_user}"]
            email_domains = ["*"]
            reverse_proxy = true
            set_xauthrequest = true
            proxy_websockets = true
            redirect_url = "https://pi.${var.domain}/oauth2/callback"
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
