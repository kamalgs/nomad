variable "nomad_address" {
  description = "Nomad API address"
  type        = string
  default     = "http://localhost:4646"
}

variable "domain" {
  type    = string
  default = "gkamal.online"
}

variable "oauth_client_id" {
  type      = string
  sensitive = true
}

variable "oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "oauth_cookie_secret" {
  type      = string
  sensitive = true
}

variable "oauth_github_user" {
  type = string
}

variable "marimo_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "marimo_oauth_client_secret" {
  type      = string
  sensitive = true
}

# ── Admin console (Metabase) ─────────────────────────────────────────────────
# GitHub OAuth app dedicated to admin.finadvisor.gkamal.online — authorised
# callback URL: https://admin.finadvisor.gkamal.online/oauth2/callback
variable "admin_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "admin_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "admin_oauth_cookie_secret" {
  type      = string
  sensitive = true
}

# ── pi-agent-dashboard ───────────────────────────────────────────────────────
# GitHub OAuth app dedicated to pi.gkamal.online — authorised callback URL:
# https://pi.gkamal.online/oauth2/callback
variable "pi_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "pi_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "pi_oauth_cookie_secret" {
  type      = string
  sensitive = true
}

variable "pi_dashboard_repo" {
  type        = string
  default     = "/home/agent/projects/phi-dev-setup/pi-agent-dashboard"
  description = "Absolute path to the pi-agent-dashboard checkout the raw_exec task runs from."
}

variable "metabase_ro_password" {
  type        = string
  sensitive   = true
  description = "Password for the metabase_ro Postgres role (SELECT-only on a curated subset)."
}

variable "openwebui_secret_key" {
  type      = string
  sensitive = true
}

variable "finadvisor_anthropic_api_key" {
  type      = string
  sensitive = true
}

variable "together_api_key" {
  type      = string
  sensitive = true
}

variable "openrouter_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "resend_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "resend_from" {
  type    = string
  default = "Benji <noreply@finadvisor.gkamal.online>"
}

variable "subprime_admin_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "smtp_host" {
  type    = string
  default = ""
}

variable "smtp_port" {
  type    = string
  default = "587"
}

variable "smtp_user" {
  type    = string
  default = ""
}

variable "smtp_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "smtp_from" {
  type    = string
  default = "noreply@finadvisor.gkamal.online"
}

variable "subprime_otp_cheat" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Optional bypass code for OTP verification (empty = disabled)"
}

variable "subprime_experiment" {
  type        = string
  default     = "prod"
  description = "Label attached to every OTEL span/metric so Jaeger and Prometheus can aggregate by experiment (e.g. 'prod', 'ctx-optimize-rc1')."
}

variable "subprime_prompt_version" {
  type        = string
  default     = ""
  description = "Optional prompt version label on OTEL resources (e.g. 'v2')."
}

variable "hyperdx_ingest_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Bearer token for HyperDX's OTLP collector. Read from /etc/otel/supervisor-data/effective.yaml inside the hyperdx container, or copy from HyperDX UI → Team Settings → Ingestion API Key."
}

# ── Blue-green deployment ─────────────────────────────────────────────────────
# The deploy script targets one colour at a time by setting this variable,
# terraform-applying just the corresponding `nomad_job.finadvisor_<colour>`,
# smoke-testing the inactive colour, then flipping Caddy's active pointer.

variable "finadvisor_blue_image" {
  type        = string
  default     = "finadvisor:local"
  description = "Docker image for the blue finadvisor job. Deploy script may override via -var or TF_VAR_finadvisor_blue_image."
}

variable "finadvisor_green_image" {
  type        = string
  default     = "finadvisor:local"
  description = "Docker image for the green finadvisor job."
}

# ── SES (for OTP email; SMTP mailpit is the dev fallback) ────────────────────

variable "ses_from_address" {
  type        = string
  default     = ""
  description = "SES sender, e.g. 'Benji <noreply@finadvisor.gkamal.online>'. Empty = use SMTP fallback."
}

variable "ses_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for SES (must match where the sender is verified)."
}

variable "ses_aws_access_key_id" {
  type        = string
  sensitive   = true
  default     = ""
  description = "IAM access key restricted to ses:SendEmail on the verified sender."
}

variable "ses_aws_secret_access_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Secret for ses_aws_access_key_id."
}

# ── AI Gateway + Workers AI ──────────────────────────────────────────────────

variable "ai_gateway_base_url" {
  type        = string
  default     = ""
  description = "Cloudflare AI Gateway base URL, e.g. 'https://gateway.ai.cloudflare.com/v1/<acct>/<gw>'. Empty → providers hit direct."
}

variable "ai_gateway_cache_version" {
  type        = string
  default     = ""
  description = "Suffix appended to AI Gateway's cache key. Bump to force cache invalidation after a prompt change."
}

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Cloudflare token with Workers AI read access. Used as the Authorization header for workers-ai:* models routed through AI Gateway."
}

variable "advisor_model_basic" {
  type        = string
  default     = ""
  description = "Basic-tier advisor model override. Empty → basic tier uses ADVISOR_MODEL. Intended for a small Workers AI model (e.g. 'workers-ai:@cf/meta/llama-3.3-70b-instruct-fp8-fast')."
}

variable "advisor_model" {
  type        = string
  default     = "workers-ai:@cf/meta/llama-3.3-70b-instruct-fp8-fast"
  description = "Default advisor model — used for Premium tier and as the Basic-tier fallback when advisor_model_basic is empty."
}

variable "refine_model" {
  type        = string
  default     = "none"
  description = "Senior-reviewer model for the refine pass. 'none' skips refinement. Set to a workers-ai or anthropic model to enable."
}
