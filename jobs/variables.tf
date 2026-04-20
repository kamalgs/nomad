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
