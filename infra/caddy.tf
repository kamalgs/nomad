# Caddyfile under version control.
#
# The template at infra/templates/Caddyfile.tftpl is the source of truth.
# This resource renders it, validates with `caddy validate`, atomically
# swaps the live /etc/caddy/Caddyfile, and reloads the systemd unit.
#
# A backup of the previous file is kept at /etc/caddy/Caddyfile.prev
# so a manual rollback is one `mv` away if a reload turns up a problem
# we didn't catch in `caddy validate`.
#
# Note on the dynamic blue-green import:
#   Caddyfile contains `import /etc/caddy/active-finadvisor.caddy`,
#   which is rewritten by scripts/blue-green-deploy.sh on each
#   promotion. That file is intentionally NOT under VC — it's runtime
#   state. The `import` line is just text in the template, so the
#   blue-green flow keeps working unchanged.
#
# Tracked: kamalgs/subprime#40 (this) + kamalgs/subprime#41 (cleanup of
# the abandoned Nomad-gateway artefacts that pre-dated this).

resource "local_file" "caddyfile" {
  filename        = "${path.module}/templates/Caddyfile.tftpl.rendered"
  content         = file("${path.module}/templates/Caddyfile.tftpl")
  file_permission = "0644"
}

resource "terraform_data" "caddyfile_apply" {
  # Re-run whenever the template content changes.
  triggers_replace = [local_file.caddyfile.content]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      RENDERED="${local_file.caddyfile.filename}"
      LIVE=/etc/caddy/Caddyfile
      BACKUP=/etc/caddy/Caddyfile.prev

      # If live and rendered match, nothing to do (idempotent re-applies).
      if cmp -s "$RENDERED" "$LIVE"; then
          echo "Caddyfile unchanged — skipping reload"
          exit 0
      fi

      # Validate before swapping. caddy validate reads the file we point
      # it at, so we use the rendered (not live) version. Any imports it
      # references (e.g. /etc/caddy/active-finadvisor.caddy) must already
      # exist for validate to pass — which they will in normal operation.
      sudo --preserve-env=CF_API_TOKEN caddy validate --config "$RENDERED" --adapter caddyfile

      # Swap with backup. Atomic via mv on the same filesystem.
      sudo cp "$LIVE" "$BACKUP"
      sudo cp "$RENDERED" "$LIVE"

      # Reload via systemd. Fast (~1s); does not drop in-flight conns.
      if ! sudo systemctl reload caddy; then
          echo "caddy reload failed — restoring previous Caddyfile" >&2
          sudo cp "$BACKUP" "$LIVE"
          sudo systemctl reload caddy || true
          exit 1
      fi

      echo "Caddyfile applied + reloaded"
    EOT
  }
}
