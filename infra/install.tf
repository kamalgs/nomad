resource "terraform_data" "nomad_install" {
  triggers_replace = [var.nomad_version]

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Install Docker
      apt-get update && apt-get install -y docker.io
      systemctl enable docker && systemctl start docker

      # Install Nomad
      tmp=$(mktemp -d)
      curl -fsSL "https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip" -o "$tmp/nomad.zip"
      unzip -o "$tmp/nomad.zip" -d "${var.install_dir}"
      chmod +x "${var.install_dir}/nomad"
      rm -rf "$tmp"
      mkdir -p "${var.data_dir}" "${var.config_dir}" "/opt/nomad/volumes/caddy_data" "/opt/nomad/volumes/jupyter_data" "/opt/nomad/volumes/o3000y_data" "/opt/nomad/volumes/hyperdx_data" "/opt/nomad/volumes/foliozzz_data" "/opt/nomad/caddy/apps" "/opt/nomad/launcher"

      # Seed initial Caddy route snippets (port assignments in PORTS.md)
      cat > /opt/nomad/caddy/apps/o3000y.caddy << 'CADDY'
o3000y.gkamal.online {
    encode zstd gzip
    reverse_proxy {
        to localhost:8081 localhost:9090
        lb_policy first
        lb_retries 1
        fail_duration 10s
    }
}
CADDY

      cat > /opt/nomad/caddy/apps/alphaa.caddy << 'CADDY'
alphaa.gkamal.online {
    encode zstd gzip
    reverse_proxy {
        to localhost:8000 localhost:9090
        lb_policy first
        lb_retries 1
        fail_duration 10s
    }
}
CADDY

      cat > /opt/nomad/caddy/apps/hyperdx.caddy << 'CADDY'
hyperdx.gkamal.online {
    encode zstd gzip
    reverse_proxy localhost:8080
}
CADDY

      cat > /opt/nomad/caddy/apps/jupyter.caddy << 'CADDY'
jupyter.gkamal.online {
    encode zstd gzip
    reverse_proxy {
        to 127.0.0.1:4180 localhost:9090
        lb_policy first
        lb_retries 1
        fail_duration 10s
    }
}
CADDY

      cat > /opt/nomad/caddy/apps/foliozzz.caddy << 'CADDY'
foliozzz.gkamal.online {
    encode zstd gzip
    reverse_proxy localhost:8085
}
CADDY

      # Seed launcher apps config with on-demand apps
      test -f /opt/nomad/launcher/apps.json || cat > /opt/nomad/launcher/apps.json << 'JSON'
{"jupyter.gkamal.online": {"job": "jupyter", "group": "jupyter", "port": 4180, "idle_timeout": 900}, "o3000y.gkamal.online": {"job": "o3000y", "group": "app", "port": 8081, "idle_timeout": 900}, "alphaa.gkamal.online": {"job": "alphaa", "group": "app", "port": 8000, "idle_timeout": 900}}
JSON
    EOT
  }
}
