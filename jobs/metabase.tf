resource "nomad_job" "metabase" {
  jobspec = <<-EOT
    job "metabase" {
      datacenters = ["dc1"]
      type        = "service"

      group "metabase" {
        count = 1

        network {
          mode = "host"
        }

        # Reuses the finadvisor_data host volume — Metabase persists its
        # H2 metadata DB under /app/state/metabase/ inside the container,
        # which lands at /opt/nomad/volumes/finadvisor_data/metabase/ on disk.
        volume "finadvisor_data" {
          type      = "host"
          source    = "finadvisor_data"
          read_only = false
        }

        task "metabase" {
          driver = "docker"

          config {
            image        = "metabase/metabase:latest"
            network_mode = "host"
          }

          env {
            MB_DB_FILE   = "/app/state/metabase/metabase.db"
            MB_JETTY_PORT = "${local.ports.metabase}"
            # Bind to loopback only — oauth2-proxy is the only allowed ingress.
            MB_JETTY_HOST = "127.0.0.1"
          }

          volume_mount {
            volume      = "finadvisor_data"
            destination = "/app/state"
          }

          resources {
            cpu    = 500
            memory = 1024
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
            http_address = "127.0.0.1:${local.ports.admin_oauth}"
            upstreams = ["http://127.0.0.1:${local.ports.metabase}"]
            provider = "github"
            client_id = "${var.admin_oauth_client_id}"
            client_secret = "${var.admin_oauth_client_secret}"
            cookie_secret = "${var.admin_oauth_cookie_secret}"
            cookie_secure = true
            cookie_name = "_oauth2_proxy_admin"
            github_users = ["${var.oauth_github_user}"]
            email_domains = ["*"]
            reverse_proxy = true
            set_xauthrequest = true
            proxy_websockets = true
            redirect_url = "https://admin.finadvisor.${var.domain}/oauth2/callback"
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
