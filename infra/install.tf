resource "terraform_data" "nomad_install" {
  triggers_replace = [var.nomad_version]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      tmp=$(mktemp -d)
      curl -fsSL "https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip" -o "$tmp/nomad.zip"
      unzip -o "$tmp/nomad.zip" -d "${var.install_dir}"
      chmod +x "${var.install_dir}/nomad"
      rm -rf "$tmp"
      mkdir -p "${var.data_dir}" "${var.config_dir}" "/opt/nomad/volumes/caddy_data" "/opt/nomad/caddy/apps" "/opt/nomad/launcher"

      # Seed initial Caddy route snippets for existing apps
      cat > /opt/nomad/caddy/apps/dev.caddy << 'CADDY'
dev.gkamal.online {
    reverse_proxy localhost:3000
}
CADDY

      cat > /opt/nomad/caddy/apps/o3000ly.caddy << 'CADDY'
o3000ly.gkamal.online {
    reverse_proxy localhost:8080
}
CADDY

      cat > /opt/nomad/caddy/apps/alphaa.caddy << 'CADDY'
alphaa.gkamal.online {
    reverse_proxy 127.0.0.1:8000
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

      # Seed launcher apps config with jupyter as on-demand
      test -f /opt/nomad/launcher/apps.json || echo '{"jupyter.gkamal.online": {"job": "jupyter", "group": "jupyter", "port": 4180, "idle_timeout": 900}}' > /opt/nomad/launcher/apps.json
    EOT
  }
}
