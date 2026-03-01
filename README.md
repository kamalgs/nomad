# Nomad Single-Node Platform

A single-node Nomad setup for running apps on one server with automatic HTTPS, on-demand scaling, and a one-command deploy workflow.

## Architecture

```
Internet
  │
  ▼
Caddy (gateway job)         ← auto-HTTPS via Let's Encrypt
  │
  ├─► app on localhost:PORT ← always-on apps
  │
  └─► app OR launcher:9090 ← on-demand apps (Caddy tries app first, falls back to launcher)
        │
        └─► Nomad API       ← launcher scales app from 0→1, returns a loading page
```

All apps use host networking. Caddy routes requests by hostname (`<name>.gkamal.online`).

### On-Demand Lifecycle

1. App is deployed with `count=0` and a Caddy failover route to the launcher
2. First request hits the launcher, which scales the job to 1 and returns a loading page
3. The page auto-refreshes; once the app is healthy, Caddy routes directly to it
4. A background scaler thread monitors TCP connections via `ss`
5. After `idle_timeout` seconds with zero connections, the scaler scales the job back to 0

## Project Structure

```
.
├── deploy                  # CLI tool to deploy/remove/list apps
├── infra/                  # Terraform: Nomad installation & systemd service
│   ├── install.tf          #   download binary, create dirs, seed configs
│   ├── config.tf           #   write nomad.hcl from template
│   ├── service.tf          #   systemd unit + enable/start
│   ├── variables.tf        #   nomad_version, data_dir, etc.
│   ├── outputs.tf          #   nomad_address, version, data_dir
│   └── templates/
│       ├── nomad.hcl.tftpl     # server+client config, host volumes, plugin config
│       └── nomad.service.tftpl # systemd unit template
└── jobs/                   # Terraform: Nomad job definitions
    ├── gateway.tf          #   Caddy reverse proxy (imports /apps/*.caddy)
    ├── launcher.tf         #   on-demand wake-up service + idle scaler
    └── jupyter.tf          #   JupyterLab + oauth2-proxy (on-demand)
```

### Key Files on Disk

| Path | Purpose |
|------|---------|
| `/opt/nomad/caddy/apps/*.caddy` | Per-app Caddy route snippets |
| `/opt/nomad/launcher/apps.json` | On-demand app registry (hot-reloaded by launcher) |
| `/opt/nomad/volumes/caddy_data/` | Caddy TLS certificates and state |
| `/etc/nomad.d/nomad.hcl` | Nomad agent configuration |

## Setup

### 1. Install Nomad

```sh
cd infra
terraform init
terraform apply
```

This installs the Nomad binary, writes the config, and starts the systemd service.

### 2. Deploy Jobs

```sh
cd jobs
terraform init
terraform apply
```

This deploys the gateway (Caddy), launcher, and jupyter jobs.

## Deploy an App

```
./deploy <name> <image> <port> [options]
```

**Options:**
- `--ondemand` &mdash; scale-to-zero app, woken on first request
- `--idle-timeout N` &mdash; seconds before idle scale-down (default: 900)
- `--cpu N` &mdash; CPU shares (default: 256)
- `--memory N` &mdash; memory in MB (default: 512)
- `-e KEY=VALUE` &mdash; environment variable (repeatable)

**Examples:**

```sh
# Always-on app
./deploy myapp nginx:alpine 8080

# On-demand app with 5-minute idle timeout
./deploy myapp nginx:alpine 8080 --ondemand --idle-timeout 300
```

**Other commands:**

```sh
./deploy --ls          # list deployed apps
./deploy --rm myapp    # remove an app
```

## apps.json Schema

The launcher reads `/opt/nomad/launcher/apps.json` every 30 seconds. Format:

```json
{
  "myapp.gkamal.online": {
    "job": "myapp",
    "group": "myapp",
    "port": 8080,
    "idle_timeout": 900
  }
}
```

- `port` and `idle_timeout` are required for automatic scale-down
- Entries missing these fields are still woken up by the launcher but never scaled down
- The file is hot-reloaded; no restart needed after edits
