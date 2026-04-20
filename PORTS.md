# Port Registry

All services use **host networking** on a single VM — ports must be globally unique.
Check this file before assigning a new port.

## Ranges

| Range | Purpose |
|-------|---------|
| 80, 443 | Caddy gateway (external HTTP/HTTPS) |
| 4180–4199 | Auth proxies (oauth2-proxy, etc.) |
| 4220–4299 | NATS / messaging |
| 4300–4399 | gRPC services |
| 4646 | Nomad API (reserved) |
| 8000–8099 | Application HTTP |
| 8800–8899 | Internal tooling |
| 9090–9099 | Platform services |

## Assignments

| Port | Service | Purpose | Managed in |
|------|---------|---------|------------|
| 80 | Caddy | HTTP (auto-redirect to HTTPS) | `jobs/gateway.tf` |
| 443 | Caddy | HTTPS termination | `jobs/gateway.tf` |
| 4180 | oauth2-proxy | Jupyter auth proxy | `jobs/jupyter.tf` |
| 4181 | oauth2-proxy | Marimo auth proxy | `jobs/marimo.tf` |
| 4317 | HyperDX | OTLP gRPC collector | `jobs/hyperdx.tf` |
| 4318 | HyperDX | OTLP HTTP collector | `jobs/hyperdx.tf` |
| 4222 | nats-server | NATS upstream TCP | `jobs/nats-chat.tf` |
| 4223 | leaf-gateway | NATS leaf TCP | `jobs/nats-chat.tf` |
| 4224 | leaf-gateway | NATS leaf WebSocket | `jobs/nats-chat.tf` |
| 4327 | o3000y | gRPC API | `o3000y` repo `.nomad.hcl` |
| 4646 | Nomad | API (reserved by Nomad itself) | system |
| 8000 | alphaa | HTTP | `alphaa` repo `.nomad.hcl` |
| 8080 | HyperDX | Web UI | `jobs/hyperdx.tf` |
| 16686 | Jaeger | Web UI (count=0 fallback) | `jobs/jaeger.tf` |
| 8081 | o3000y | REST API | `o3000y` repo `.nomad.hcl` |
| 8082 | Open WebUI | Web UI | `jobs/openwebui.tf` |
| 8085 | foliozzz | Web UI | `jobs/foliozzz.tf` |
| 8086 | nats-chat | Chat web UI | `jobs/nats-chat.tf` |
| 8090 | llm-gateway | KrakenD LLM proxy | `jobs/llm-gateway.tf` |
| 8888 | HyperDX | Internal metrics (not configurable) | `jobs/hyperdx.tf` |
| 8800 | marimo | Reactive notebook | `jobs/marimo.tf` |
| 8899 | Jupyter | Notebook server | `jobs/jupyter.tf` |
| 9090 | Launcher | Scale-to-zero launcher | `jobs/launcher.tf` |

## Next Available

| Range | Next available |
|-------|---------------|
| 4180–4199 | 4182 |
| 4220–4299 | 4225 |
| 4300–4399 | 4328 |
| 8000–8099 | 8091 |
| 8800–8899 | 8801 |
| 9090–9099 | 9091 |

## Notes

- **Terraform-managed jobs** (`jobs/*.tf`) reference ports via `local.ports.*` defined
  in `jobs/ports.tf`. Change the port in one place there.
- **Standalone `.nomad.hcl` files** (alphaa, o3000y) hardcode ports — `nomad job run`
  cannot resolve Terraform locals. Use this file as reference.
- **HyperDX internal ports** (4317, 4318, 8888) are baked into the all-in-one image and
  cannot be changed. Port 8888 conflicts with JupyterLab's default — that's why Jupyter
  runs on 8899.
